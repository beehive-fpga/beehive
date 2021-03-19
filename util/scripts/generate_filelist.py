import argparse
import os, sys
from pathlib import Path, PurePath
import yaml

class File():
    def __init__(self, attributes):
        self.is_include_file = False
        for attr, value in attributes.items():
            setattr(self, attr, value)

    def set_abspath_from(self, from_dir):
        self.name = str(Path(from_dir, self.name).resolve())

    def __repr__(self):
        return (f"core: {self.core} "
                f"file_type: {self.file_type} "
                f"name: {self.name} "
                f"is_include_file: {self.is_include_file}\n")

def main():
    if "BEEHIVE_PROJECT_ROOT" not in os.environ:
        raise RuntimeError("BEEHIVE_PROJECT_ROOT env variable not set")

    parser = setup_parser()
    args = parser.parse_args()

    files_list = []
    inc_files_list = []
    with open(args.edam_file, "r") as file_data:
        full_file = yaml.safe_load(file_data)
        edam_file_dir = str(Path(args.edam_file).resolve().parent)
        for file in full_file["files"]:
            new_file = File(file)
            new_file.set_abspath_from(edam_file_dir)
            if new_file.is_include_file:
                inc_files_list.append(new_file)
            else:
                files_list.append(new_file)

    if args.target == "corundum_fpga":
        gen_corundum_fpga_filelist(files_list, inc_files_list, args.output_file)
    elif args.target == "cocotb_sim":
        gen_cocotb_filelist(files_list, inc_files_list, args.output_file)
    elif args.target == "flist":
        gen_flist_filelist(files_list, inc_files_list, args.output_file)

    else:
        raise RuntimeError(("I have no idea how we got here. Things are very"
                "messed up"))

def gen_corundum_fpga_filelist(files_list, inc_files_list, output_file):
    # find Beehive's root
    beehive_root = os.environ["BEEHIVE_PROJECT_ROOT"]
    with open(output_file, "w") as out_file:
        # Collect all the files
        for file in inc_files_list:
            relpath_str = (PurePath(file.name).relative_to(
                Path(beehive_root).resolve()))
            out_file.write((f"SYN_FILES += $(addprefix $(BEEHIVE_ROOT),"
                    f"{relpath_str})\n"))
        for file in files_list:
            relpath_str = (PurePath(file.name).relative_to(
                Path(beehive_root).resolve()))
            out_file.write((f"SYN_FILES += $(addprefix $(BEEHIVE_ROOT),"
                    f"{relpath_str})\n"))

        out_file.write("\n")

        # Collect all the include files
        for file in inc_files_list:
            relpath_str = (PurePath(file.name).relative_to(
                Path(beehive_root).resolve()))
            out_file.write((f"INC_FILES += $(addprefix $(BEEHIVE_ROOT),"
                f"{relpath_str})\n"))

def gen_cocotb_filelist(files_list, inc_files_list, output_file):
    # find Beehive's root
    beehive_root = os.environ["BEEHIVE_PROJECT_ROOT"]

    incdirs = set()
    for file in inc_files_list:
        new_incdir = PurePath(file.name).parent
        if str(new_incdir) not in incdirs:
            incdirs.add(str(new_incdir))

    with open(output_file, "w") as out_file:
        # add the incdirs as compile args
        for incdir in incdirs:
            out_file.write(f"COMPILE_ARGS += \"+incdir+{incdir}\"\n")

        for file in files_list:
            if file.file_type == "systemVerilogSource":
                out_file.write(f"VERILOG_SOURCES += {file.name}\n")
            elif file.file_type == "vhdlSource":
                out_file.write(f"VHDL_SOURCES += {file.name}\n")


def gen_flist_filelist(files_list, inc_files_list, output_file):
    incdirs = set()
    for file in inc_files_list:
        new_incdir = PurePath(file.name).parent
        if str(new_incdir) not in incdirs:
            incdirs.add(str(new_incdir))

    with open(output_file, "w") as flist:
        for incdir in incdirs:
            flist.write(f"+incdir+{incdir}\n")

        for file in files_list:
            flist.write(f"{file.name}\n")


def setup_parser():
    parser = argparse.ArgumentParser(description=('Process an EDAM file from'
        'edalize into some sort of filelist, depending on the tool'))
    parser.add_argument("--target", choices=["corundum_fpga", "cocotb_sim", "flist"],
                        help="what tool are we generating this file for",
                        required=True)
    parser.add_argument("--edam_file",
                        help=("what edalize EDAM file we should be processing"),
                        required=True)
    parser.add_argument("--output_file",
                        required=True,
                        help=("where to write the Verilog filelist to"))
#    parser.add_argument("--output_file",
#                        required=False,
#                        help=("where to write the VHDL filelist to"))

    return parser

if __name__ == "__main__":
    main()
