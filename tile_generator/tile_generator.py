import xml.etree.ElementTree as ET
import logging
from enum import Enum

TOPOLOGY_FILE="./tile_config.xml"


"""
    Overall configuration class
"""
class BeehiveConfig():
    def __init__(self, XML_file):
        self.tree = ET.parse(XML_file)
        config = self.tree.getroot()
        self.tiles = config.find("tiles")

        nocs = config.find("nocs")
        self.nocs = []
        self.nocs_data_width = {}
        for noc in nocs:
            noc_name = noc.find("noc_name").text
            noc_width = noc.find("noc_width_def").text
            self.nocs.append(noc_name)
            self.nocs_data_width[noc_name] = noc_width

        self.total_num_tiles = 0
        self.num_x_tiles = int(self.tiles.find("num_x_tiles").text)
        self.num_y_tiles = int(self.tiles.find("num_y_tiles").text)
        self.endpoint_dict = self.createEndpointDict(self.tiles)

        if self.total_num_tiles != (self.num_x_tiles * self.num_y_tiles):
            logging.info("Tile list doesn't fill all the tiles, empty tiles "\
                    "will be inserted")

        self.fixupTileList()

    def fixupTileList(self):
        # Iterate the tile list and figure out which tuples do exist
        endpoint_set = set()
        for endpoint in self.endpoint_dict.values():
            x_y = (endpoint.endpoint_x, endpoint.endpoint_y)
            if x_y in endpoint_set:
                raise ValueError(f"Two tiles have the same coordinates: {x_y}")
            else:
                endpoint_set.add(x_y)

        # Iterate the possible combinations to figure out which tiles don't
        # exist
        num_empty = 0
        for x in range(0, self.num_x_tiles):
            for y in range(0, self.num_y_tiles):
                test_x_y = (x, y)
                if test_x_y not in endpoint_set:
                    logging.info(f"Adding an empty tile at ({x}, {y})")
                    endpoint_el = ET.Element("endpoint")
                    endpoint_name = ET.SubElement(endpoint_el, "endpoint_name")
                    endpoint_name.text = f"empty_tile{num_empty}"
                    port_name = ET.SubElement(endpoint_el, "port_name")
                    port_name.text = f"empty_tile"
                    endpoint_x = ET.SubElement(endpoint_el, "endpoint_x")
                    endpoint_x.text = f"{x}"
                    endpoint_y = ET.SubElement(endpoint_el, "endpoint_y")
                    endpoint_y.text = f"{y}"
                    empty_tile = Endpoint(endpoint_el)
                    self.endpoint_dict[f"empty_tile{num_empty}"] = empty_tile
                    num_empty += 1

    def createEndpointDict(self, XML_root):
        endpoints = {}
        for endpoint in XML_root.findall("endpoint"):
            new_endpoint = Endpoint(endpoint)
            endpoints[new_endpoint.endpoint_name] = new_endpoint
            self.total_num_tiles += 1

        return endpoints


    def getTileWires(self, endpoint):
        wires_str = """"""
        format_string = """
    logic                           {noc_id}_{outgoing}_val;
    logic   [{noc_data_width}-1:0]  {noc_id}_{outgoing}_data;
    logic                           {noc_id}_{incoming}_yummy;
    """
        format_dict = {}
        for noc in self.nocs:
            format_dict["noc_id"] = noc
            format_dict["noc_data_width"] = self.nocs_data_width[noc]
            # outgoing north connection for this tile if it exists
            if endpoint.endpoint_y > 0:
                format_dict["outgoing"] = endpoint.gen_outgoing_wire(TileDirs.NORTH)
                format_dict["incoming"] = endpoint.gen_incoming_wire(TileDirs.NORTH)
                wires_str += format_string.format(**format_dict)
            # outgoing east connection for this tile if it exists
            if endpoint.endpoint_x < (self.num_x_tiles - 1):
                format_dict["outgoing"] = endpoint.gen_outgoing_wire(TileDirs.EAST)
                format_dict["incoming"] = endpoint.gen_incoming_wire(TileDirs.EAST)
                wires_str += format_string.format(**format_dict)

            # outgoing south connection for this tile if it exists
            if endpoint.endpoint_y < (self.num_y_tiles - 1):
                format_dict["outgoing"] = endpoint.gen_outgoing_wire(TileDirs.SOUTH)
                format_dict["incoming"] = endpoint.gen_incoming_wire(TileDirs.SOUTH)
                wires_str += format_string.format(**format_dict)

            # outgoing west connection for this tile if it exists
            if endpoint.endpoint_x > 0:
                format_dict["outgoing"] = endpoint.gen_outgoing_wire(TileDirs.WEST)
                format_dict["incoming"] = endpoint.gen_incoming_wire(TileDirs.WEST)
                wires_str += format_string.format(**format_dict)

        return wires_str

    def printWires(self):
        for endpoint in self.endpoint_dict.values():
            print(self.getTileWires(endpoint))


    def getEndpointCoords(self, endpoint_name):
        if (endpoint_name not in self.endpoint_dict.keys()):
            raise ValueError("Endpoint does not exist")

        endpoint = self.endpoint_dict[endpoint_name]

        return (endpoint.endpoint_x, endpoint.endpoint_y)

    def getEndpointXParam(self, endpoint_name):
        if endpoint_name not in self.endpoint_dict.keys():
            raise ValueError("Endpoint does not exist")

        endpoint = self.endpoint_dict[endpoint_name]
        return endpoint.get_x_coord_param()

    def getEndpointYParam(self, endpoint_name):
        if endpoint_name not in self.endpoint_dict.keys():
            raise ValueError("Endpoint does not exist")

        endpoint = self.endpoint_dict[endpoint_name]
        return endpoint.get_y_coord_param()


    def getEndpointPorts(self, endpoint_name):
        if (endpoint_name not in self.endpoint_dict.keys()):
            raise ValueError("Endpoint does not exist")

        endpoint = self.endpoint_dict[endpoint_name]
        noc_ports = ""
        for noc in self.nocs:
            conn_dict = self.getTileConns(endpoint, noc)
            noc_ports += endpoint.gen_noc_ports_str(conn_dict, noc)
            noc_ports += "\n"

        return noc_ports

    def getEmptyTiles(self):
        empty_tiles = """"""
        for endpoint in self.endpoint_dict.values():
            if endpoint.port_name[0:10] == "empty_tile":
                empty_tiles += f"""
    empty_tile #(
        .SRC_X ({endpoint.endpoint_name.upper()}_X  )
        ,.SRC_Y ({endpoint.endpoint_name.upper()}_Y  )
    ) {endpoint.endpoint_name}_{endpoint.endpoint_x}_{endpoint.endpoint_y} (
        .clk   (clk)
        ,.rst   (rst)
    """
                noc_ports = ""
                for noc in self.nocs:
                    conn_dict = self.getTileConns(endpoint, noc)
                    noc_ports += endpoint.gen_noc_ports_str(conn_dict, noc)
                    noc_ports += "\n"
                empty_tiles += noc_ports
                empty_tiles += """
    );
    """
        return empty_tiles

    def getTileConns(self, endpoint, noc):
        conn_dict = {}
        bus_wires = ["val", "data", "yummy"]
        for wire in bus_wires:
            conn_dict[f"N_outgoing_{wire}"] = ""
            conn_dict[f"N_incoming_{wire}"] = "'0"
            conn_dict[f"S_outgoing_{wire}"] = ""
            conn_dict[f"S_incoming_{wire}"] = "'0"
            conn_dict[f"W_outgoing_{wire}"] = ""
            conn_dict[f"W_incoming_{wire}"] = "'0"
            conn_dict[f"E_outgoing_{wire}"] = ""
            conn_dict[f"E_incoming_{wire}"] = "'0"

        if endpoint.endpoint_y > 0:
            outgoing_wire = endpoint.gen_outgoing_wire(TileDirs.NORTH)
            incoming_wire = endpoint.gen_incoming_wire(TileDirs.NORTH)
            for wire in bus_wires:
                conn_dict[f"N_outgoing_{wire}"] = f"{noc}_{outgoing_wire}_{wire}"
                conn_dict[f"N_incoming_{wire}"] = f"{noc}_{incoming_wire}_{wire}"

        if endpoint.endpoint_y < (self.num_y_tiles - 1):
            outgoing_wire = endpoint.gen_outgoing_wire(TileDirs.SOUTH)
            incoming_wire = endpoint.gen_incoming_wire(TileDirs.SOUTH)
            for wire in bus_wires:
                conn_dict[f"S_outgoing_{wire}"] = f"{noc}_{outgoing_wire}_{wire}"
                conn_dict[f"S_incoming_{wire}"] = f"{noc}_{incoming_wire}_{wire}"

        if endpoint.endpoint_x > 0:
            outgoing_wire = endpoint.gen_outgoing_wire(TileDirs.WEST)
            incoming_wire = endpoint.gen_incoming_wire(TileDirs.WEST)
            for wire in bus_wires:
                conn_dict[f"W_outgoing_{wire}"] = f"{noc}_{outgoing_wire}_{wire}"
                conn_dict[f"W_incoming_{wire}"] = f"{noc}_{incoming_wire}_{wire}"

        if endpoint.endpoint_x < (self.num_x_tiles - 1):
            outgoing_wire = endpoint.gen_outgoing_wire(TileDirs.EAST)
            incoming_wire = endpoint.gen_incoming_wire(TileDirs.EAST)
            for wire in bus_wires:
                conn_dict[f"E_outgoing_{wire}"] = f"{noc}_{outgoing_wire}_{wire}"
                conn_dict[f"E_incoming_{wire}"] = f"{noc}_{incoming_wire}_{wire}"

        return conn_dict

class Interface():
    _req_simple_attrs = ["if_name", "fbits"]
    def __init__(self, if_xml_root, parent_endpoint):
        for attr in self._req_simple_attrs:
            xml_attr = if_xml_root.find(attr)
            if xml_attr is None:
                raise AttributeError(f"Required attribute {attr} missing")
            setattr(self, attr, xml_attr.text)

        self.parent_endpoint = parent_endpoint

        # look for interface destinations. There may be none, if it only
        # receives
        self.dsts = []
        dsts = if_xml_root.find("dsts")
        if dsts is not None:
            for dst_endpoint in dsts.findall("dst_endpoint"):
                dst_entry = {}
                for attr in dst_endpoint:
                    if attr.text is None:
                        dst_entry[attr.tag] = True
                    else:
                        dst_entry[attr.tag] = attr.text
                self.dsts.append(dst_entry)

        self.depends_on = []
        depends_on = if_xml_root.findall("depends_on")
        for dependency in depends_on:
            dependency_entry = dependency.attrib
            self.depends_on.append(dependency_entry)

    def get_interface_graph_name(self):
        return f"{self.parent_endpoint.endpoint_name}_{self.if_name}"

    def get_node_display_label(self):
        return (f"{self.if_name}\n"
                f"{self.parent_endpoint.get_node_display_label('')}")

    def __repr__(self):
        return str(vars(self))

class Endpoint():
    _req_simple_attrs = ["endpoint_name", "port_name", "endpoint_x", "endpoint_y"]
    def __init__(self, endpoint_xml_root):
        # do the required attributes
        for attr in self._req_simple_attrs:
            xml_attr = endpoint_xml_root.find(attr)
            if xml_attr is None:
                raise AttributeError(f"Required attribute {attr} missing")
            setattr(self, attr, xml_attr.text)

        self.endpoint_x = int(self.endpoint_x)
        self.endpoint_y = int(self.endpoint_y)

        # look for interfaces
        self.interfaces = {}
        interfaces = endpoint_xml_root.find("interfaces")
        if interfaces is not None:
            for interface in interfaces:
                new_interface = Interface(interface, self)
                self.interfaces[new_interface.if_name] = new_interface

    def get_endpoint_graph_name(self, noc_name=None, direction=None):
        base_name = f"{self.endpoint_name}"
        if noc_name is not None:
            base_name += f"_{noc_name}"
        if direction is not None:
            base_name += f"_{direction}"
        base_name += f"_{self.endpoint_x}_{self.endpoint_y}"
        return base_name

    def get_node_display_label(self, noc_name=None, direction=None):
        display_str = f"{self.endpoint_name}\n"
        if noc_name is not None:
            display_str += f"_{noc_name}"
        if direction is not None:
            display_str += f"{direction}\n"
        display_str += f"({self.endpoint_x}, {self.endpoint_y})"
        return display_str


    def get_x_coord_param(self):
        return f"{self.endpoint_name.upper()}_X"

    def get_y_coord_param(self):
        return f"{self.endpoint_name.upper()}_Y"

    def get_x_coord_param(self):
        return f"{self.endpoint_name.upper()}_X"

    def get_y_coord_param(self):
        return f"{self.endpoint_name.upper()}_Y"

    def add_attrs(self, endpoint_dict):
        for attr, value in endpoint_dict.items():
            if attr in self._req_attrs:
                continue
            setattr(self, attr, value)

    def gen_noc_ports_str(self, wire_dict, noc):
        # empty_tile module wires are not numbered 
        if (self.port_name[0:10] == "empty_tile"):
            wire_dict["port_name"] = "empty_tile"
        else:
            wire_dict["port_name"] = self.port_name

        ports_string = ""

        tile_format_str = '''
        ,.src_{port_name}_{noc_name}_data_N    ({N_incoming_data}  )
        ,.src_{port_name}_{noc_name}_data_E    ({E_incoming_data}  )
        ,.src_{port_name}_{noc_name}_data_S    ({S_incoming_data}  )
        ,.src_{port_name}_{noc_name}_data_W    ({W_incoming_data}  )

        ,.src_{port_name}_{noc_name}_val_N     ({N_incoming_val}   )
        ,.src_{port_name}_{noc_name}_val_E     ({E_incoming_val}   )
        ,.src_{port_name}_{noc_name}_val_S     ({S_incoming_val}   )
        ,.src_{port_name}_{noc_name}_val_W     ({W_incoming_val}   )

        ,.{port_name}_src_{noc_name}_yummy_N   ({N_outgoing_yummy} )
        ,.{port_name}_src_{noc_name}_yummy_E   ({E_outgoing_yummy} )
        ,.{port_name}_src_{noc_name}_yummy_S   ({S_outgoing_yummy} )
        ,.{port_name}_src_{noc_name}_yummy_W   ({W_outgoing_yummy} )

        ,.{port_name}_dst_{noc_name}_data_N    ({N_outgoing_data}  )
        ,.{port_name}_dst_{noc_name}_data_E    ({E_outgoing_data}  )
        ,.{port_name}_dst_{noc_name}_data_S    ({S_outgoing_data}  )
        ,.{port_name}_dst_{noc_name}_data_W    ({W_outgoing_data}  )

        ,.{port_name}_dst_{noc_name}_val_N     ({N_outgoing_val}   )
        ,.{port_name}_dst_{noc_name}_val_E     ({E_outgoing_val}   )
        ,.{port_name}_dst_{noc_name}_val_S     ({S_outgoing_val}   )
        ,.{port_name}_dst_{noc_name}_val_W     ({W_outgoing_val}   )

        ,.dst_{port_name}_{noc_name}_yummy_N   ({N_incoming_yummy} )
        ,.dst_{port_name}_{noc_name}_yummy_E   ({E_incoming_yummy} )
        ,.dst_{port_name}_{noc_name}_yummy_S   ({S_incoming_yummy} )
        ,.dst_{port_name}_{noc_name}_yummy_W   ({W_incoming_yummy} )'''

        wire_dict["noc_name"] = noc
        return tile_format_str.format(**wire_dict)

    def gen_outgoing_wire(self, direction):
        return self._gen_port_wire(direction, False)

    def gen_incoming_wire(self, direction):
        return self._gen_port_wire(direction, True)

    def _gen_port_wire(self, direction, incoming):
        this_endpoint = f"endpoint_{self.endpoint_x}_{self.endpoint_y}"
        other_endpoint = ""
        if (direction == TileDirs.NORTH):
            other_endpoint = f"endpoint_{self.endpoint_x}_{self.endpoint_y - 1}"
        elif (direction == TileDirs.EAST):
            other_endpoint = f"endpoint_{self.endpoint_x + 1}_{self.endpoint_y}"
        elif (direction == TileDirs.SOUTH):
            other_endpoint = f"endpoint_{self.endpoint_x}_{self.endpoint_y + 1}"
        elif (direction == TileDirs.WEST):
            other_endpoint = f"endpoint_{self.endpoint_x - 1}_{self.endpoint_y}"
        else:
            raise ValueException("Somehow we just got a completely baffling" \
                    "tile direction")

        if incoming:
            return f"{other_endpoint}_{this_endpoint}"
        else:
            return f"{this_endpoint}_{other_endpoint}"

    def __repr__(self):
        # Print all the attributes
        return str(vars(self))

class TileDirs(Enum):
    NORTH = 0
    EAST = 1
    SOUTH = 2
    WEST = 3

    TILE_DIRS = [NORTH, EAST, SOUTH, WEST]

#def main():
#    tile_config = BeehiveConfig(TOPOLOGY_FILE)
#
#if __name__ == "__main__":
#    main()
