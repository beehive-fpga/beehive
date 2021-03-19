from cocotb.binary import BinaryValue
import socket

class BeehiveNoCConstants:
    NOC_DATA_W              = 512
    MSG_DST_CHIPID_WIDTH    = 14
    MSG_DST_X_WIDTH         = 8
    MSG_DST_Y_WIDTH         = 8
    MSG_DST_FBITS_WIDTH     = 4
    MSG_LENGTH_WIDTH        = 22
    MSG_TYPE_WIDTH          = 8
    MSG_SRC_CHIPID_WIDTH    = MSG_DST_CHIPID_WIDTH
    MSG_SRC_X_WIDTH         = MSG_DST_X_WIDTH
    MSG_SRC_Y_WIDTH         = MSG_DST_Y_WIDTH
    MSG_SRC_FBITS_WIDTH     = MSG_DST_FBITS_WIDTH
    MSG_METADATA_FLITS_W    = 8
    MSG_ADDR_WIDTH          = 48
    MSG_DATA_SIZE_WIDTH     = 30


class BeehiveFlit():
    def __init__(self):
        flit_width = 0
        for field, width in self.fields.items():
            setattr(self, field, BinaryValue(value=0, n_bits=width,bigEndian=False))
            flit_width += width

    def assemble_flit(self):
        bitstrings = [None] * len(self.fields)
        i = 0
        for field in self.fields:
            binary_val = getattr(self, field)
            bitstrings[i] = binary_val.binstr
            i += 1

        full_bitstring = "".join(bitstrings)
        padding = BeehiveNoCConstants.NOC_DATA_W - len(full_bitstring)
        pad_str = ""
        if padding > 0:
            pad_str = "0"*padding

        padded_bitstring = full_bitstring + pad_str
        #return padded_bitstring

        final_bin_value = BinaryValue(value=0, n_bits=BeehiveNoCConstants.NOC_DATA_W)
        final_bin_value.binstr = full_bitstring
        return final_bin_value

    def set_field(self, field, value):
        binary_field = getattr(self, field)
        binary_field.assign(value)

    def flit_from_bitstring(self, bitstring):
        bitstr_index = 0
        for (field, width) in self.fields.items():
            bin_value = getattr(self, field)
            bin_value.binstr = bitstring[bitstr_index:bitstr_index+width]
            bitstr_index += width


    def __repr__(self) -> str:
        values = [None] * len(self.fields)
        i = 0
        for field in self.fields:
            binary_val = getattr(self, field)
            if (i == (len(self.fields) - 1)):
                values[i] = f"{field}: {binary_val.binstr}\n"
            else:
                values[i] = f"{field}: {binary_val.binstr}, "
            i += 1

        all_values = "".join(values)
        return all_values

class BeehiveHdrFlit(BeehiveFlit):
    fields = {
        "dst_chipid": BeehiveNoCConstants.MSG_DST_CHIPID_WIDTH,
        "dst_x": BeehiveNoCConstants.MSG_DST_X_WIDTH,
        "dst_y": BeehiveNoCConstants.MSG_DST_Y_WIDTH,
        "dst_fbits": BeehiveNoCConstants.MSG_DST_FBITS_WIDTH,
        "msg_length": BeehiveNoCConstants.MSG_LENGTH_WIDTH,
        "msg_type": BeehiveNoCConstants.MSG_TYPE_WIDTH,
        "src_chipid": BeehiveNoCConstants.MSG_SRC_CHIPID_WIDTH,
        "src_x": BeehiveNoCConstants.MSG_SRC_X_WIDTH,
        "src_y": BeehiveNoCConstants.MSG_DST_X_WIDTH,
        "src_fbits": BeehiveNoCConstants.MSG_SRC_FBITS_WIDTH,
        "metadata_flits": BeehiveNoCConstants.MSG_METADATA_FLITS_W,
        "addr": BeehiveNoCConstants.MSG_ADDR_WIDTH,
        "data_size": BeehiveNoCConstants.MSG_DATA_SIZE_WIDTH
    }

class BeehiveIPFlit(BeehiveFlit):
    fields = {
        "src_ip": 32,
        "dst_ip": 32,
        "payload_len": 16,
        "protocol": 8
    }

    def set_field(self, field, value):
        set_value = value
        if (field == "src_ip") or field == "dst_ip":
            if not isinstance(value, str):
                raise ValueError("Please provide the IPs as strings")
            ip_addr_bytes = socket.inet_aton(value)
            rev_bytes = ip_addr_bytes[::-1]
            set_value = rev_bytes
        super().set_field(field, set_value)

class BeehiveUDPFlit(BeehiveFlit):
    fields = {
        "src_ip": 32,
        "dst_ip": 32,
        "src_port": 16, 
        "dst_port": 16,
        "payload_len": 16,
    }
    
    def set_field(self, field, value):
        set_value = value
        if (field == "src_ip") or field == "dst_ip":
            if not isinstance(value, str):
                raise ValueError("Please provide the IPs as strings")
            ip_addr_bytes = socket.inet_aton(value)
            rev_bytes = ip_addr_bytes[::-1]
            set_value = rev_bytes
        super().set_field(field, set_value)
