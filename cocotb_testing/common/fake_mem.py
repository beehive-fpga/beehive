import cocotb
from cocotb_bus.bus import Bus
from cocotb.binary import BinaryValue
from cocotb.triggers import Timer, RisingEdge, First, ReadOnly, ClockCycles
from random import Random

from abc import ABC, abstractmethod

"""
    A wrapper for a bus to be used as the input to a DRAM

    entity: whatever Bus expects. Probably your dut

    signals: a dictionary mapping signalNames to signal objects. You must have
    all the signals defined in _signalNames
"""
class MemInputBus(Bus):
    _signalNames = ["wr_en", "rd_en", "addr", "wr_data", "byte_en", "rdy"]
    def __init__(self, entity, signals):
        for name in self._signalNames:
            if not name in signals:
                raise AttributeError(f"signals doesn't contain a value for key" \
                    f"{name}")
        super().__init__(entity, "", signals, case_insensitive=False)

"""
    A wrapper for a bus to be used as the output to a DRAM

    entity: whatever Bus expects. Probably your dut

    signals: a dictionary mapping signalNames to signal objects. You must have
    all the signals defined in _signalNames
"""
class MemOutputBus(Bus):
    _signalNames = ["rd_val", "rd_data", "rd_rdy"]
    def __init__(self, entity, signals):
        for name in self._signalNames:
            if not name in signals:
                raise AttributeError(f"signals doesn't contain a value for key" \
                    f"{name}")
        super().__init__(entity, "", signals, case_insensitive=False)

class FakeMem():
    def __init__(self, tb, mem_width=512, mem_depth=1024, input_delay_gen=None,
            op_delay_gen=None):
        self.tb = tb
        self.mem_width = mem_width
        self.mem_bytes = int(mem_width/8)
        self.mem = [bytearray([0] * self.mem_bytes) for i in range(mem_depth)]

        self.input_delay_gen = input_delay_gen
        self.op_delay_gen = op_delay_gen

    def read_mem(self, address, length):
        block_addr_width = (self.mem_bytes - 1).bit_length()
        block_addr_mask = (1 << block_addr_width) - 1

        res_buf = bytearray()
        iter_addr = address
        # there's a more efficient way to do this, but i want something i know
        # is correct
        for i in range(0, length):
            line_addr = iter_addr >> block_addr_width
            block_addr = iter_addr & block_addr_mask

            byte = self.mem[line_addr][block_addr]

            res_buf.append(byte)

            iter_addr += 1

        return res_buf


    def read_mem(self, address, length):
        block_addr_width = (self.mem_bytes - 1).bit_length()
        block_addr_mask = (1 << block_addr_width) - 1

        res_buf = bytearray()
        iter_addr = address
        # there's a more efficient way to do this, but i want something i know
        # is correct
        for i in range(0, length):
            line_addr = iter_addr >> block_addr_width
            block_addr = iter_addr & block_addr_mask

            byte = self.mem[line_addr][block_addr]

            res_buf.append(byte)

            iter_addr += 1

        return res_buf


    async def run_mem(self):
        while True:
            if self.input_delay_max is not None:
                self.tb.mem_input.rdy.value = 1
                await ReadOnly()

                if (self.tb.mem_input.wr_en.value == 0 and
                        self.tb.mem_input.rd_en.value == 0):
                    await First(RisingEdge(self.tb.mem_input.wr_en),
                                RisingEdge(self.tb.mem_input.rd_en))
                await ReadOnly()
            else:
                await ReadOnly()

                if (self.tb.mem_input.wr_en.value == 0 and
                        self.tb.mem_input.rd_en.value == 0):
                    await First(RisingEdge(self.tb.mem_input.wr_en),
                                RisingEdge(self.tb.mem_input.rd_en))

                delay = self.input_delay_gen.get_delay()
                await ClockCycles(self.tb.dut.clk, delay)
                self.tb.mem_input.rdy.value = 1

                await ReadOnly()

            mem_op_res = self._do_mem_op()

            await RisingEdge(self.tb.dut.clk)
            self.tb.mem_input.rdy.value = 0

            if mem_op_res != None:
                await self._out_mem_read(mem_op_res)

    async def _out_mem_read(self, data):
        if self.op_delay_gen is not None:
            delay = self.op_delay_gen.get_delay()
            await ClockCycles(self.tb.dut.clk, delay)

        self.tb.mem_output.rd_val.value = 1
        self.tb.mem_output.rd_data.value = data
        await ReadOnly()

        if self.tb.mem_output.rd_rdy.value != 1:
            await RisingEdge(self.tb.mem_output.rd_rdy)

        await RisingEdge(self.tb.dut.clk)
        self.tb.mem_output.rd_val.value = 0
        self.tb.mem_output.rd_data.value = BinaryValue(value=0, n_bits=self.mem_width)

    def _do_mem_op(self):
        # if we're doing a read
        op_addr = self.tb.mem_input.addr.value
        if self.tb.mem_input.rd_en.value == 1:
            mem_line = self.mem[op_addr];
            return BinaryValue(value=bytes(mem_line), n_bits=self.mem_width)
        else:
            wr_mask = self.tb.mem_input.byte_en.value.binstr
            wr_data = self.tb.mem_input.wr_data.value.buff
            for i in range(0, self.mem_bytes):
                if wr_mask[i] == "1":
                    self.mem[op_addr][i] = wr_data[i]

class MemDelayGen(ABC):
    @abstractmethod
    def get_delay(self):
        pass

class RandomDelay(MemDelayGen):
    def __init__(self, seed, max_delay):
        self.rand_gen = Random()
        self.rand_gen.seed(seed)
        self.max_delay = max_delay

    def get_delay(self):
        return self.rand_gen.randint(1, self.max_delay)

class ConstDelay(MemDelayGen):
    def __init__(self, delay):
        self.delay = delay

    def get_delay(self):
        return self.delay
