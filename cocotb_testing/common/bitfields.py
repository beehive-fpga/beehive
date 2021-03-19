import copy

class AbstractStruct():
    def __init__(self, init_bitstring=None):
        if init_bitstring is not None:
            self.fromBinaryString(init_bitstring)

    def setField(self, field_name, value):
        index = self.bitfield_indices[field_name]
        self.bitfields[index].set_value(value)

    def getField(self, field_name):
        index = self.bitfield_indices[field_name]
        return self.bitfields[index].value

    def getBitfield(self, field_name):
        index = self.bitfield_indices[field_name]
        return self.bitfields[index]

    def toBinaryString(self):
        field_manip = bitfieldManip(self.bitfields)
        bitstr = field_manip.gen_bitstring()
        return bitstr

    def getWidth(self):
        total_w = 0
        for bitfield in self.bitfields:
            total_w += bitfield.size

        return total_w

    def fromBinaryString(self, bitstr):
        bitstring_index = 0
        for field in self.bitfields:
            value_bitstr = field.parse_bitstring(bitstr[bitstring_index:])
            value = field.value_fr_bitstring(value_bitstr)
            field.set_value(value)

            bitstring_index += len(value_bitstr)

    def __repr__(self):
        repr_str = ""
        for bitfield in self.bitfields:
            repr_str += f"{bitfield}\n"
        return repr_str

    def __eq__(self, other):
        if not isinstance(other, AbstractStruct):
            return False
        else:
            isEqual = True
            for bitfield in self.bitfields:
                other_bitfield = other.getBitfield(bitfield.name)
                isEqual = isEqual and (bitfield.value == other_bitfield.value)

            return isEqual

class bitfieldManip:
    """
    A class to manipulate bitstrings given the specification of one or more bitfields
    within the string

    Attributes
    --------
    fields : array
    an array of bitfield objects in the order of the bitfields in the bitstring

    bitstring_len : int
    the total length of the bitstring expected given the length of each bitfield object
    """
    def __init__(self, fields):
        self.fields = fields;
        self.bitstring_len = 0;
        for field in fields:
            self.bitstring_len += field.size


    def split_bitstring(self, bitstring):
        if len(bitstring) < self.bitstring_len:
            raise ValueException(f"Argument bitstring should be at least of length \
                    {self.bitstring_len}, but is length {len(bitstring)}")

        bitstring_index = 0
        bitfields = []
        for field in self.fields:
            value_bitstring = field.parse_bitstring(bitstring[bitstring_index:])
            value = field.value_fr_bitstring(value_bitstring)

            new_bitfield = copy.deepcopy(field)
            new_bitfield.set_value(value)

            bitfields.append(new_bitfield)

            bitstring_index += len(value_bitstring)

        rem_bits = len(bitstring) - bitstring_index
        if rem_bits > 0:
            padding_bitstring = bitstring[bitstring_index:]
            new_bitfield = bitfield("padding", rem_bits, value=int(padding_bitstring, 2))

            bitfields.append(new_bitfield)

        return bitfields

    def gen_bitstring(self):
        concat_bitstring = []
        for field in self.fields:
            field_bitstring = field.bitfield_format()
            concat_bitstring.append(field_bitstring)

        concat_bitstring = "".join(concat_bitstring)

        return concat_bitstring


class bitfield:
    """
    A simple class to hold information about a bitfield

    Attributes
    --------
    name : str
        name of the bitfield

    size : int
        number of bits in the bitfield

    value : int
        the value of this bitfield currently
    """
    def __init__(self, name, size, value=0, trunc_value=False):
        """
        Constructs a new bitfield

        Parameters
        ---------
        name : str
            name of the bitfield

        size : int
            number of bits in the bitfield

        value : int (optional)
            the value to initialize the bitfield with
        """
        self.name = name
        self.size = size
        self.trunc_value = trunc_value
        if not self.trunc_value:
            if value > ((1 << size) - 1):
                raise ValueException(f"Value cannot be greater than {(1<<size) - 1}")
        self.value = value

    def set_value(self, value):
        """
        Change the value currently associated with the bitfield

        Parameters
        -------
        value : int
            the new value to associate with the bitfield
        """
        assign_val = value
        if not self.trunc_value:
            if value > ((1 << self.size) - 1):
                raise ValueException(f"Value can't be greater than {(1 << size) - 1}")
        # truncate the value
        else:
            mask = (1 << self.size) - 1
            assign_val = value & mask
        self.value = assign_val

    def parse_bitstring(self, bitstring):
        """
        From a bitstring, parse the first x bits that represent this bitfield

        Parameters
        ------
        bitstring : str
        the bitstring to parse

        Returns
        ------
        bitfield_str : str
        A substring of the bitstring starting at index 0 that represents this bitfield
        """
        if len(bitstring) < self.size:
            raise ValueException("Bitstring isn't long enough to contain this bitfield")

        return bitstring[0:self.size]


    def bitfield_format(self):
        """
        Get the formatted bitstring of the current value associated with the bitfield

        Returns
        -------
        The bitstring representation of value with size bits
        """
        format_str = f"{{0:0{self.size}b}}"
        return format_str.format(self.value)[-self.size:]


    def value_fr_bitstring(self, bitstring):
        return int(bitstring[-self.size:], 2)

    def __str__(self):
        str_rep = f"name: {self.name}, size: {self.size}, value: {self.value}"
        return str_rep
