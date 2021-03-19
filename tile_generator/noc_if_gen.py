class NocInterfaceTemplates:
    ROUTER_PROCESSOR_DECL_TEMPLATE="""
    ,output                                 {module}_{processor}_{noc_name}_val
    ,output [{noc_data_width}-1:0]          {module}_{processor}_{noc_name}_data
    ,input                                  {processor}_{module}_{noc_name}_yummy

    ,input                                  {processor}_{module}_{noc_name}_val
    ,input  [{noc_data_width}-1:0]          {processor}_{module}_{noc_name}_data
    ,output                                 {module}_{processor}_{noc_name}_yummy"""

    ROUTER_PROCESSOR_INST_TEMPLATE="""
        ,.{module}_{processor}_{noc_name}_val    ({inst_name}_ctovr_{noc_name}_val     )
        ,.{module}_{processor}_{noc_name}_data   ({inst_name}_ctovr_{noc_name}_data    )
        ,.{processor}_{module}_{noc_name}_yummy  (ctovr_{inst_name}_{noc_name}_yummy   )

        ,.{processor}_{module}_{noc_name}_val    (vrtoc_{inst_name}_{noc_name}_val     )
        ,.{processor}_{module}_{noc_name}_data   (vrtoc_{inst_name}_{noc_name}_data    )
        ,.{module}_{processor}_{noc_name}_yummy  ({inst_name}_vrtoc_{noc_name}_yummy   )"""

    ROUTER_PROCESSOR_WIRES_TEMPLATE="""
    logic                           vrtoc_{inst_name}_{noc_name}_val;
    logic   [{noc_data_width}-1:0]  vrtoc_{inst_name}_{noc_name}_data;
    logic                           {inst_name}_vrtoc_{noc_name}_yummy;

    logic                           {inst_name}_ctovr_{noc_name}_val;
    logic   [{noc_data_width}-1:0]  {inst_name}_ctovr_{noc_name}_data;
    logic                           ctovr_{inst_name}_{noc_name}_yummy;
    """

    MODULE_DECL_TEMPLATE="""
    ,input [{noc_data_width}-1:0]           {src}_{module}_{noc_name}_data_N
    ,input [{noc_data_width}-1:0]           {src}_{module}_{noc_name}_data_E
    ,input [{noc_data_width}-1:0]           {src}_{module}_{noc_name}_data_S
    ,input [{noc_data_width}-1:0]           {src}_{module}_{noc_name}_data_W

    ,input                                  {src}_{module}_{noc_name}_val_N
    ,input                                  {src}_{module}_{noc_name}_val_E
    ,input                                  {src}_{module}_{noc_name}_val_S
    ,input                                  {src}_{module}_{noc_name}_val_W

    ,output                                 {module}_{src}_{noc_name}_yummy_N
    ,output                                 {module}_{src}_{noc_name}_yummy_E
    ,output                                 {module}_{src}_{noc_name}_yummy_S
    ,output                                 {module}_{src}_{noc_name}_yummy_W

    ,output [{noc_data_width}-1:0]          {module}_{dst}_{noc_name}_data_N
    ,output [{noc_data_width}-1:0]          {module}_{dst}_{noc_name}_data_E
    ,output [{noc_data_width}-1:0]          {module}_{dst}_{noc_name}_data_S
    ,output [{noc_data_width}-1:0]          {module}_{dst}_{noc_name}_data_W

    ,output                                 {module}_{dst}_{noc_name}_val_N
    ,output                                 {module}_{dst}_{noc_name}_val_E
    ,output                                 {module}_{dst}_{noc_name}_val_S
    ,output                                 {module}_{dst}_{noc_name}_val_W

    ,input                                  {dst}_{module}_{noc_name}_yummy_N
    ,input                                  {dst}_{module}_{noc_name}_yummy_E
    ,input                                  {dst}_{module}_{noc_name}_yummy_S
    ,input                                  {dst}_{module}_{noc_name}_yummy_W"""

    MODULE_INST_TEMPLATE="""
        ,.{src}_{port_name}_{noc_name}_data_N  ({noc_src}_{module}_{noc_name}_data_N )
        ,.{src}_{port_name}_{noc_name}_data_E  ({noc_src}_{module}_{noc_name}_data_E )
        ,.{src}_{port_name}_{noc_name}_data_S  ({noc_src}_{module}_{noc_name}_data_S )
        ,.{src}_{port_name}_{noc_name}_data_W  ({noc_src}_{module}_{noc_name}_data_W )

        ,.{src}_{port_name}_{noc_name}_val_N   ({noc_src}_{module}_{noc_name}_val_N  )
        ,.{src}_{port_name}_{noc_name}_val_E   ({noc_src}_{module}_{noc_name}_val_E  )
        ,.{src}_{port_name}_{noc_name}_val_S   ({noc_src}_{module}_{noc_name}_val_S  )
        ,.{src}_{port_name}_{noc_name}_val_W   ({noc_src}_{module}_{noc_name}_val_W  )

        ,.{port_name}_{src}_{noc_name}_yummy_N ({module}_{noc_src}_{noc_name}_yummy_N)
        ,.{port_name}_{src}_{noc_name}_yummy_E ({module}_{noc_src}_{noc_name}_yummy_E)
        ,.{port_name}_{src}_{noc_name}_yummy_S ({module}_{noc_src}_{noc_name}_yummy_S)
        ,.{port_name}_{src}_{noc_name}_yummy_W ({module}_{noc_src}_{noc_name}_yummy_W)

        ,.{port_name}_{dst}_{noc_name}_data_N  ({module}_{noc_dst}_{noc_name}_data_N )
        ,.{port_name}_{dst}_{noc_name}_data_E  ({module}_{noc_dst}_{noc_name}_data_E )
        ,.{port_name}_{dst}_{noc_name}_data_S  ({module}_{noc_dst}_{noc_name}_data_S )
        ,.{port_name}_{dst}_{noc_name}_data_W  ({module}_{noc_dst}_{noc_name}_data_W )

        ,.{port_name}_{dst}_{noc_name}_val_N   ({module}_{noc_dst}_{noc_name}_val_N  )
        ,.{port_name}_{dst}_{noc_name}_val_E   ({module}_{noc_dst}_{noc_name}_val_E  )
        ,.{port_name}_{dst}_{noc_name}_val_S   ({module}_{noc_dst}_{noc_name}_val_S  )
        ,.{port_name}_{dst}_{noc_name}_val_W   ({module}_{noc_dst}_{noc_name}_val_W  )

        ,.{dst}_{port_name}_{noc_name}_yummy_N ({noc_dst}_{module}_{noc_name}_yummy_N)
        ,.{dst}_{port_name}_{noc_name}_yummy_E ({noc_dst}_{module}_{noc_name}_yummy_E)
        ,.{dst}_{port_name}_{noc_name}_yummy_S ({noc_dst}_{module}_{noc_name}_yummy_S)
        ,.{dst}_{port_name}_{noc_name}_yummy_W ({noc_dst}_{module}_{noc_name}_yummy_W)"""

class NocInterfaceGen:
    # a wrapper function so we can assemble the dictionary correctly
    def genNocInterface(self, src, module, dst, nocs, noc_widths):
        interface_str = ""
        for noc in nocs:
            format_dict = {"src": src, "module": module, "dst": dst,
                           "noc_name": noc, "noc_data_width": noc_widths[noc]}
            interface_str += NocInterfaceTemplates.MODULE_DECL_TEMPLATE.format(**format_dict)
        return interface_str

    def genNocInstantiation(self, src, port_name, dst, noc_src, noc_dst, module, nocs):
        port_str = ""
        for noc in nocs:
            format_dict = {"src": src, "port_name": port_name, "dst": dst,
                        "noc_src": noc_src, "noc_dst": noc_dst, "module": module,
                        "noc_name": noc}
            port_str += NocInterfaceTemplates.MODULE_INST_TEMPLATE.format(**format_dict)
        return port_str

    def genNocProcessorInterface(self, module, processor, nocs, noc_widths):
        interface_str = ""
        for noc in nocs:
            format_dict = {"module": module, "processor": processor,
                    "noc_name": noc, "noc_data_width": noc_widths[noc]}
            interface_str += NocInterfaceTemplates.ROUTER_PROCESSOR_DECL_TEMPLATE.format(**format_dict)
        return interface_str

    def genNocProcessorInstantiation(self, module, processor, inst_name, nocs):
        port_str = ""
        for noc in nocs:
            format_dict = {"module": module, "processor": processor,
                    "inst_name": inst_name, "noc_name": noc}
            port_str += NocInterfaceTemplates.ROUTER_PROCESSOR_INST_TEMPLATE.format(**format_dict)
        return port_str

    def genNocProcessorWires(self, inst_name, nocs, noc_widths):
        wire_str = ""
        for noc in nocs:
            format_dict = {"inst_name": inst_name, "noc_name": noc, "noc_data_width": noc_widths[noc]}
            wire_str += NocInterfaceTemplates.ROUTER_PROCESSOR_WIRES_TEMPLATE.format(**format_dict)
        return wire_str
