import cocotb.utils
from cocotb.triggers import RisingEdge, ReadOnly, ClockCycles, First, Event

class TimerDisarm():
    def __init__(self, clk):
        self.event = Event()
        self.armed = False
        self.timed_out = False
        self.armed_time = 0
        self.expire_time = 0
        self.clk = clk

    async def arm_timer(self, clock_cycles):
        self.armed_time = cocotb.utils.get_sim_time(units="ns")
        self.expire_time = self.armed_time + (clock_cycles * 4)
        self.event.clear()
        time_trigger = ClockCycles(self.clk, clock_cycles)
        self.armed = True
        await First(self.event.wait(), time_trigger)

        if self.event.is_set():
            return False
        else:
            self.timed_out = True
            return True

    def disarm_timer(self):
        self.event.set()
        self.armed = False

    def __repr__(self):
        return (f"armed: {self.armed}, start_time: {self.armed_time}, "
                f"expire_time: {self.expire_time}, timed_out: {self.timed_out}")
