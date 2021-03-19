import xml.etree.ElementTree as ET
import logging
from enum import Enum
import networkx as nx
import os, sys
import argparse
import matplotlib.pyplot as plt
import pygraphviz as pgv
from pathlib import Path

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/tile_generator/")
from tile_generator import BeehiveConfig

class TileConfig():
    def __init__(self, XML_file):
        self.config_class = BeehiveConfig(XML_file)
        self.num_x_tiles = self.config_class.num_x_tiles
        self.num_y_tiles = self.config_class.num_y_tiles

        self.tile_array = [[0 for i in range(self.num_x_tiles)] for j in range(self.num_y_tiles)]
        self.graph = nx.DiGraph()

        self.fillTileArray(self.config_class.endpoint_dict)
        self.createGraph()

    def drawDependencyGraph(self, out_file_path):
        pyviz = nx.nx_agraph.to_agraph(self.graph)
        pyviz.graph_attr["overlap"] = "false"
        pyviz.graph_attr["nodesep"] = ".4"
        pyviz.node_attr["shape"] = "circle"
        pyviz.node_attr["margin"] = .01

        path = Path(out_file_path)
        pyviz.draw(path=path, prog="neato")


    def drawLayout(self, rect_width, rect_height, rect_padding):
        # calculate the dimensions in the x and y directions based on the number of tiles
        x_max = (self.num_x_tiles * rect_width) + ((self.num_x_tiles + 1) * rect_padding)
        y_max = (self.num_y_tiles * rect_height) + ((self.num_y_tiles + 1) * rect_padding)

        # take the axis max as the max of the two
        axis_max = max(x_max, y_max)
        x_offset = 0
        y_offset = 0

        if (axis_max) == x_max:
            # figure out how much excess space we have in the y direction
            excess = axis_max - y_max
            # split it over the two sides of the figure
            y_offset = excess/2.0
        else:
            excess = axis_max - x_max
            x_offset = excess/2.0

        # set up the axes
        fig, ax = plt.subplots()
        fig.set_size_inches(10, 10)
        ax.set_xlim(0, axis_max)
        ax.set_ylim(0, axis_max)
        # kill the drawn axes because they're unneccessary to draw
        ax.set_yticks([])
        ax.set_xticks([])

        # draw the rectangles
        for x in range(0, self.num_x_tiles):
            for y in range(0, self.num_y_tiles):
                # calculate where the rectangle should be
                x_pos = (x * rect_width) + ((x + 1) * rect_padding) + x_offset
                # start at the top for the y. also the anchor point is at the bottom left of
                # the rectange
                y_pos = y_max - (((y+1) * rect_height) + ((y+1) * rect_padding)) + y_offset

                # create the rectangle
                rect = plt.Rectangle((x_pos, y_pos), rect_width, rect_height, ec="black", fc="none", figure = fig)
                ax.add_patch(rect)

                # get the endpoint's name for a label
                endpoint = self.getTile(x, y)
                label_x = x_pos + rect.get_width()/2.0
                label_y = y_pos + rect.get_height()/2.0
                ax.annotate(endpoint.endpoint_name, (label_x, label_y), color="b", ha="center", va="center", fontsize=10)

        return fig, ax



    def getTile(self, x, y):
        return self.tile_array[y][x]

    def setTile(self, x, y, tile):
        self.tile_array[y][x] = tile

    def fillTileArray(self, endpoint_dict):
        for key, value in endpoint_dict.items():
            self.setTile(value.endpoint_x, value.endpoint_y, value)
    
    def _add_endpoint_nodes(self, endpoint):
        for noc_name in self.config_class.nocs:
            # add endpoint in and out to graph per-NoC
            endpoint_node_name = endpoint.get_endpoint_graph_name(noc_name=noc_name)
            self.graph.add_node(f"{endpoint_node_name}_in",
                    label=endpoint.get_node_display_label(noc_name=noc_name, direction="in"))
            self.graph.add_node(f"{endpoint_node_name}_out",
                    label=endpoint.get_node_display_label(noc_name=noc_name, direction="out"))

            # add outgoing edges to graph as necessary
            if endpoint.endpoint_y != 0:
                self.graph.add_node(f"{endpoint_node_name}_N_out",
                        label=endpoint.get_node_display_label(f"N_out"))
            if endpoint.endpoint_y != (self.num_y_tiles-1):
                self.graph.add_node(f"{endpoint_node_name}_S_out",
                        label=endpoint.get_node_display_label(f"S_out"))
            if endpoint.endpoint_x != 0:
                self.graph.add_node(f"{endpoint_node_name}_W_out",
                        label=endpoint.get_node_display_label(f"W_out"))
            if endpoint.endpoint_x != (self.num_x_tiles-1):
                self.graph.add_node(f"{endpoint_node_name}_E_out",
                        label=endpoint.get_node_display_label(f"E_out"))


    def createGraph(self):
        # add all the nodes
        for y in range(0, len(self.tile_array)):
            for x in range(0, len(self.tile_array[0])):
                endpoint = self.getTile(x, y)
                self._add_endpoint_nodes(endpoint)

                # also add interfaces
                for if_name, interface in endpoint.interfaces.items():
                    interface_node_name = interface.get_interface_graph_name()
                    self.graph.add_node(interface_node_name,
                            label=interface.get_node_display_label())


        # loop again to get destinations now that all the nodes are added

        for y in range(0, len(self.tile_array)):
            for x in range(0, len(self.tile_array[0])):
                endpoint = self.getTile(x, y)
                endpoint_node_name = endpoint.get_endpoint_graph_name()
                if len(endpoint.interfaces) != 0:
                    for if_name, interface in endpoint.interfaces.items():
                        interface_node_name = interface.get_interface_graph_name()
                        # get the destinations
                        self.addNoCDestinations(interface)
                        self.addDependencies(interface)

    def addNoCDestinations(self, interface):
        for dst in interface.dsts:
            dst_endpoint_obj = self.config_class.endpoint_dict[dst["endpoint_name"]]
            dst_interface = dst_endpoint_obj.interfaces[dst["if_name"]]
            noc_name = "data_noc0"
            if "noc_name" in dst:
                noc_name = dst["noc_name"]

            self.addEdges(interface, dst_interface, noc_name=noc_name)

    def addDependencies(self, interface):
        src_interface_node = interface.get_interface_graph_name()
        for dep in interface.depends_on:
            # get the destination interface
            dst_endpoint_obj = self.config_class.endpoint_dict[dep["endpoint_name"]]
            dst_interface = dst_endpoint_obj.interfaces[dep["if_name"]]
            dst_interface_node = dst_interface.get_interface_graph_name()

            self.graph.add_edge(src_interface_node, dst_interface_node)


    def addEdges(self, src_interface, dst_interface, noc_name):
        # add an edge from the interface to the endpoint on the appropriate noc
        src_interface_node = src_interface.get_interface_graph_name()
        src_endpoint_node = src_interface.parent_endpoint.get_endpoint_graph_name(noc_name=noc_name)
        self.graph.add_edge(src_interface_node, f"{src_endpoint_node}_out")

        curr_x = src_interface.parent_endpoint.endpoint_x
        curr_y = src_interface.parent_endpoint.endpoint_y
        dst_x = dst_interface.parent_endpoint.endpoint_x
        dst_y = dst_interface.parent_endpoint.endpoint_y
        last_node = f"{src_interface.parent_endpoint.get_endpoint_graph_name(noc_name=noc_name)}_out"

        while not (curr_x == dst_x and curr_y == dst_y):
            # go in the x direction first
            next_node_name = self.getTile(curr_x, curr_y).get_endpoint_graph_name(noc_name=noc_name)
            # go west
            if curr_x > dst_x:
                next_node_name += "_W_out"
                curr_x -= 1
            # go east
            elif curr_x < dst_x:
                next_node_name += "_E_out"
                curr_x += 1
            # go north
            elif curr_y > dst_y:
                next_node_name += "_N_out"
                curr_y -= 1
            # go south
            elif curr_y < dst_y:
                next_node_name += "_S_out"
                curr_y += 1
            else:
                raise RuntimeError("We shouldn't reach this case")


            self.graph.add_edge(last_node, next_node_name)
            last_node = next_node_name

        # okay now add to the processing unit
        dst_endpoint = dst_interface.parent_endpoint
        self.graph.add_edge(last_node,
                f"{dst_endpoint.get_endpoint_graph_name(noc_name=noc_name)}_in")

        # okay now add to the interface
        self.graph.add_edge(f"{dst_endpoint.get_endpoint_graph_name(noc_name=noc_name)}_in",
                dst_interface.get_interface_graph_name())


def setup_graph():
    parser = argparse.ArgumentParser(description=('Process a tile config file '
        'into a graph we can analyze for deadlock'))

    parser.add_argument("--input_file", help="XML file containing the tile config",
                        required=True)

    return parser

def main():
    if "BEEHIVE_PROJECT_ROOT" not in os.environ:
        raise RuntimeError("BEEHIVE_PROJECT_ROOT env variable not set")

    parser = setup_parser()
    args = parser.parse_args()
    config = None

    with open(args.input_file, "r") as file_data:
        config = TileConfig(file_data)

if __name__ == "__main__":
    main()

