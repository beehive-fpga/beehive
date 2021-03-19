def get_num_dst_localparam_str(interface):
    cond_string_templ = "(SRC_X == {x_coord}) && (SRC_Y == {y_coord})"
    endpoint = interface.parent_endpoint

    cam_dsts = 0
    for dst in interface.dsts:
        if "cam_target" in dst:
            cam_dsts += 1
    cond_string = cond_string_templ.format(x_coord = endpoint.endpoint_x,
                                           y_coord = endpoint.endpoint_y)

    ternary = f"""{cond_string}
        ? {cam_dsts}
        : """
    return ternary

def get_dst_x_localparam_str(config, interface):
    return __get_dst_localparam_str(config, interface, get_x=True)

def get_dst_y_localparam_str(config, interface):
    return __get_dst_localparam_str(config, interface, get_x=False)

def __get_dst_localparam_str(config, interface, get_x):
    cond_string_templ = "(SRC_X == {x_coord}) && (SRC_Y == {y_coord})"
    endpoint = interface.parent_endpoint
    dst_endpoint = interface.dsts[0]
    dst_endpoint_obj = config.endpoint_dict[dst_endpoint["endpoint_name"]]

    cond_string = cond_string_templ.format(x_coord = endpoint.endpoint_x,
                                           y_coord = endpoint.endpoint_y)
    dst_param = ""
    if get_x:
        dst_param = dst_endpoint_obj.get_x_coord_param()
    else:
        dst_param = dst_endpoint_obj.get_y_coord_param()

    ternary = f"""{cond_string}
        ? {dst_param}
        : """
    return ternary

