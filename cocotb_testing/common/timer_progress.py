from cocotb.triggers import RisingEdge, ReadOnly, ClockCycles

class TimerProgress():
    def __init__(self, log, timer_name=""):
        if len(timer_name) != 0:
            self.timer_title = f"{timer_name}: "
        else:
            self.timer_title = ""
        self.log = log

    async def arm_timer(self, clock_cycles, step_cycles, clk):
        num_cycles = clock_cycles
        self.log.info(f"{self.timer_title}armed for {num_cycles}")
        while num_cycles > 0:
            if (num_cycles <= step_cycles):
                await ClockCycles(clk, num_cycles)
                num_cycles = 0
            else:
                await ClockCycles(clk, step_cycles)
                num_cycles -= step_cycles
                self.log.info(f"{self.timer_title}{num_cycles} left to wait")
