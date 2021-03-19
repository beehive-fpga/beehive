import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

@cocotb.test()
async def check_chksum_update(dut):
    dut.old_chksum.setimmediatevalue(0)
    dut.old_ip_addr.setimmediatevalue(0)
    dut.new_ip_addr.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, 4, units='ns').start())
    await RisingEdge(dut.clk)

    ip_pkt = IP()
    ip_pkt.src = "198.0.0.1"
    ip_pkt.dst = "198.0.0.7"
    ip_pkt.flags = "DF"

    tcp_pkt = TCP()
    tcp_pkt.sport = 50000
    tcp_pkt.dport = 65432
    tcp_pkt.seq = 40000
    tcp_pkt.ack = 50000
    tcp_pkt.window = 64240

    test_pkt = ip_pkt/tcp_pkt
    # build to force checksum computation
    test_pkt_bytes = test_pkt.build()

    # recast back to extract fields
    extract_pkt = IP(test_pkt_bytes)

    dut.old_chksum.value = BinaryValue(value=extract_pkt["TCP"].chksum.to_bytes(2, "big"))
    dut.old_ip_addr.value = BinaryValue(value=socket.inet_aton(extract_pkt["IP"].src))
    dut.new_ip_addr.value = BinaryValue(value=socket.inet_aton("198.0.0.5"))

    # get the reference checksum
    update_pkt = extract_pkt.copy()
    update_pkt["IP"].src = "198.0.0.5"
    update_pkt["IP"].chksum = None
    update_pkt["TCP"].chksum = None
    update_pkt_bytes = update_pkt.build()

    ref_pkt = IP(update_pkt_bytes)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # check the output
    await ReadOnly()

    ref_chksum = ref_pkt["TCP"].chksum.to_bytes(2, "big")

    if (dut.new_chksum.value.buff != ref_chksum):
        print(f"Updated chskum is {dut.new_chksum.value.buff}, "
              f"Reference is {ref_chksum}")
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        raise RuntimeError()

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
