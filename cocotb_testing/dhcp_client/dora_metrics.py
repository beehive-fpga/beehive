"""Cycle/byte measurement helpers for the DHCP DORA path.

These produce concrete numbers for the offload-vs-CPU comparison in the
datasheet: Beehive's dhcp_tile runs DORA autonomously, so the CPU spends
zero cycles on it. The wall-clock cycle count below is the tile-side
budget; the comparison story pairs it with a software baseline measured
elsewhere (Cohort + rdcycle).
"""
from dataclasses import dataclass, field, asdict
from typing import Dict

import cocotb
from cocotb.triggers import RisingEdge


# Mirror dhcp_tile_pkg.sv:dhcp_client_state_e.
_STATE_NAMES = {
    0: "INIT",
    1: "SELECTING",
    2: "REQUESTING",
    3: "BOUND",
    4: "RENEWING",
    5: "REBINDING",
}


@dataclass
class DoraMetrics:
    """Per-state cycle counts plus aggregate transfer counts.

    All fields are clock cycles unless noted. cpu_cycles is fixed at 0:
    the dhcp_tile drives DORA autonomously, so the host CPU does no
    work over the same interval. Filed here so the comparison plot has
    a side-by-side column for the software baseline."""
    cycles_per_state: Dict[str, int] = field(default_factory=dict)
    cycles_total: int = 0
    cpu_cycles: int = 0
    # Tile-active cycles: MAC TX OR MAC RX asserting val (rdy-independent
    # so a stall waiting for the other side still counts as active work).
    # Complement (cycles_total - mac_active_cycles) is timer/wait idle.
    # For the CPU comparison this is the honest "service time" number;
    # idle cycles also happen on a CPU dhclient waiting for the server.
    mac_active_cycles: int = 0
    tx_beats: int = 0
    rx_beats: int = 0
    tx_frames: int = 0
    rx_frames: int = 0

    def as_dict(self) -> Dict[str, int]:
        d = asdict(self)
        d["cycles_per_state"] = dict(self.cycles_per_state)
        return d

    def log_summary(self, log, label: str = "DORA") -> None:
        log.info(f"{label} metrics:")
        log.info(f"  cycles_total       = {self.cycles_total}")
        log.info(f"  mac_active_cycles  = {self.mac_active_cycles}")
        idle = self.cycles_total - self.mac_active_cycles
        log.info(f"  mac_idle_cycles    = {idle}")
        for st in self.cycles_per_state:
            log.info(f"  cycles_in_{st:<11s}= {self.cycles_per_state[st]}")
        log.info(f"  cpu_cycles         = {self.cpu_cycles} (tile is autonomous)")
        log.info(f"  tx_beats / frames  = {self.tx_beats} / {self.tx_frames}")
        log.info(f"  rx_beats / frames  = {self.rx_beats} / {self.rx_frames}")


class _CycleSampler:
    """Background coroutine: each posedge clk, accumulate one cycle into
    the bucket named by the current value of lease_state_dbg, and tick
    counters for any val&rdy MAC beat we observe."""

    def __init__(self, dut):
        self.dut = dut
        self.metrics = DoraMetrics()
        self._stop = False
        self._task = None

    def start(self):
        self._task = cocotb.start_soon(self._run())

    def stop(self):
        self._stop = True

    async def _run(self):
        dut = self.dut
        while not self._stop:
            await RisingEdge(dut.clk)
            self.metrics.cycles_total += 1

            try:
                st_v = int(dut.DHCP_TILE_3_0.tile.ctrl.lease_state_dbg.value)
                name = _STATE_NAMES.get(st_v, f"UNK_{st_v}")
                self.metrics.cycles_per_state[name] = \
                    self.metrics.cycles_per_state.get(name, 0) + 1
            except Exception:
                pass

            tx_val = int(dut.engine_mac_tx_val.value)
            rx_val = int(dut.mac_engine_rx_val.value)
            if tx_val or rx_val:
                self.metrics.mac_active_cycles += 1

            if tx_val and int(dut.mac_engine_tx_rdy.value):
                self.metrics.tx_beats += 1
                if int(dut.engine_mac_tx_endframe.value):
                    self.metrics.tx_frames += 1

            if rx_val and int(dut.engine_mac_rx_rdy.value):
                self.metrics.rx_beats += 1
                if int(dut.mac_engine_rx_endframe.value):
                    self.metrics.rx_frames += 1


def start_dora_sampler(dut) -> _CycleSampler:
    """Start a background cycle/byte sampler. Returns the handle whose
    .metrics field accumulates until you call .stop()."""
    s = _CycleSampler(dut)
    s.start()
    return s
