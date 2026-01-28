# mmWAVE RFE CIR Demo FPGA Files
Performs 802.11ad CIR estimation. Transmits Golay Sequences and performs cross-correlation to estimate the CIR. 
Both monostatic (RADAR) and bistatic (communication) modes are supported. 
In the bistatic node, packet detection and synchronization are also implemented.
> [!NOTE]\
> This project requires **Vivado 2022.1**.

## Prerequisites
- RFSoC4x2 BSP, see [this guide](https://rfsoc.dev/boards/rfsoc4x2#board-files) if it is not downloaded and configured.
- For using the bitstream, install [`RFSoC-MTS` overlay](https://github.com/Xilinx/RFSoC-MTS).

## Regenerating the Vivado Project
At the directory with this `README.md` file, in Vivado, run
```tcl
source cir_sounder.tcl
```

This will create a Vivado project in the `cir_sounder/` directory.

# Contributing and Support
Want to contribute? Great! Please email info@houdini-sdr.org 

# Documentation
Other community resources can be found at the 
* [Houdini Website](https://houdini-sdr.org)  
* [Houdini Wiki](https://wiki.houdini-sdr.org)

# License
[Houdini open source license](license.md)

# Acknowledgement
Houdini is supported by National Science Foundation Grant No. CNS-2346550
