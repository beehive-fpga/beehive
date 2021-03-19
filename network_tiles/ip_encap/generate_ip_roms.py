#!/usr/bin/python3
import sys
import ipaddress

def get_bitstring_from_byte(byte):
    return "{0:08b}".format(byte)

def print_rom_files(phys_ip_rom, virt_ip_rom, ip_addr_map, cam_els):
    if (len(ip_addr_map) > int(cam_els)):
        raise AttributeError("Too many elements in the ip addr map for the" \
                            "requested CAM size")

    with open(phys_ip_rom, "w") as phys_ip_file, open(virt_ip_rom, "w") as virt_ip_file:
        for virt_ip_str, phys_ip_str in ip_addr_map.items():
            phys_ip = ipaddress.IPv4Address(phys_ip_str)
            virt_ip = ipaddress.IPv4Address(virt_ip_str)

            # Convert the ip address strings into bytes
            phys_ip_bytes = ipaddress.v4_int_to_packed(int(phys_ip))
            virt_ip_bytes = ipaddress.v4_int_to_packed(int(virt_ip))

            phys_ip_bitstring = ""
            for byte in phys_ip_bytes:
                phys_ip_bitstring += (get_bitstring_from_byte(byte) + "_")
            phys_ip_bitstring = phys_ip_bitstring.rstrip("_")

            virt_ip_bitstring = ""
            for byte in virt_ip_bytes:
                virt_ip_bitstring += (get_bitstring_from_byte(byte) + "_")
            virt_ip_bitstring = virt_ip_bitstring.rstrip("_")

            # write out the human version of the IP address
            phys_ip_file.write("# " + phys_ip_str + "\n")
            virt_ip_file.write("# " + virt_ip_str + "\n")
            # now the bitstring version of the IP address
            phys_ip_file.write(phys_ip_bitstring + "\n")
            virt_ip_file.write(virt_ip_bitstring + "\n")

if __name__=="__main__":
    if (len(sys.argv) != 4):
        print("Usage: generate_ip_roms <phys_ips_out> <virt_ips_out> <cam_els>")
        exit(1)

    ip_addr_map = {}
    ip_addr_map["198.10.100.1"] = "10.25.1.17"
    ip_addr_map["198.10.200.1"] = "10.25.1.16"

    print_rom_files(sys.argv[1], sys.argv[2], ip_addr_map, sys.argv[3])


