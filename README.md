# Beehive

Beehive is a NoC-based network stack designed for flexibility and scalability.

A lot of the network stuff lives in the TCP HW submodule for now. Stuff will be
moved out "later". Depends on whenever I have time.

## Dependencies
Some hardware simulator: Beehive has been tested using Questa FSE and ModelSim.
VCS has been used for some basic test cases. That being said, Beehive
doesn't do anything too wild with SystemVerilog and should also work in other
hardware simulators.

Python:
Beehive relies on a handful of Python scripts and Python libraries for testing
and build. Everything has been tested using Python 3.9. 

Beehive relies on cocotb for testing. It has been tested using Questa FSE with
cocotb. Beehive also relies on scapy for packet crafting during testing. It uses
FuseSoC to manage filelists.

In no particular order, here are the commands to install the various packages
with `pip`. scapy is also available thru conda (if that's relevant to you),
but cocotb and fusesoc are not.

```
pip install cocotb
pip install cocotb_bus
pip install scapy
pip install fusesoc
```

## Running a basic test
Make sure you have cloned all the submodules and installed all the dependencies.
Source `settings.sh` in the root of the repo. Make sure your working directory
is the repo root `source settings.sh`

The easiest test to run is a UDP echo test. From the root of the repo: `cd
cocotb_testing/udp_echo`

Setup FuseSoC, generate files, create filelist
```
make init_fusesoc
make gen_filelist
```

Run the test through cocotb by just running `make`. Depending on what simulator
you're using, add the appropriate variables to generate a waveform or bring up
the gui. For Questa, this is `make WAVES=1 GUI=1`

## More Documentation
This is just an ongoing work in progress. However, here's some documentation on how we generate bits of code and use FuseSoC:

- [Generating the tile top-levels](https://leather-knight-073.notion.site/Code-Generation-5fe9344c53684d91bf218ddb48bf6aa8)
- [Generating flists/build Makefiles with FuseSoC](https://leather-knight-073.notion.site/FuseSoC-and-Beehive-f579640a45ad434f90ca5640fb68b221)
