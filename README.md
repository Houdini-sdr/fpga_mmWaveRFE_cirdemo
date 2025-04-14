# 60G-radio-cir-fpga

Performs 802.11ad CIR estimation. Transmits Golay Sequences and performs cross-correlation to estimate the CIR. 

Both monostatic (RADAR) and bistatic (communication) modes are supported. 

In the bistatic node, packet detection and synchronization are also implemented. 

# Prerequisites - Install RFSoC-MTS overlay
https://github.com/Xilinx/RFSoC-MTS

# Regenerating the Vivado Project
Unzip cir_sounder.sources.zip.  cd to the folder and 

    source cir_sounder.tcl

in Vivado to regenerate the project.

