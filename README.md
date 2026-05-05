# mmWAVE RFE CIR Demo FPGA Files
Performs 802.11ad/ay-like channel impulse response (CIR) estimation for 60 GHz mmWave radio.
Transmits Golay Sequences and performs cross-correlation to estimate the CIR. 
Both monostatic (radar) and bistatic (communication) modes are supported. 
In the bistatic node, packet detection and synchronization are also implemented.

> [!NOTE]\
> This project requires **Vivado 2022.1** or higher.

## Prerequisites
- RFSoC4x2 BSP, see [this guide](https://rfsoc.dev/boards/rfsoc4x2#board-files) if it is not downloaded and configured.
- For using the bitstream, install [`RFSoC-MTS` overlay](https://github.com/Xilinx/RFSoC-MTS).

## Regenerating the Vivado Project
The user-facing entry point is the Python generator. The root `cir_sounder.tcl` is generated from `configs/cir_default.yml` and is ignored by git.

Generate the default Tcl and source it with Vivado in batch mode:
```bash
./generate_cir_sounder.py --config configs/cir_default.yml
```

This creates a Vivado project in the `cir_sounder/` directory.

To generate the Tcl without running Vivado:
```bash
./generate_cir_sounder.py --config configs/cir_default.yml --generate-only
```

You can then source the generated Tcl manually in Vivado:
```tcl
source cir_sounder.tcl
```

The default config uses RFDC `iq` mode: TX I/Q streams feed separate DAC RF ports directly, with the selected TX coarse mixers bypassed.

Other shipped config:
- `configs/cir_tx_duc.yml`: TX I/Q streams feed one DAC RF port using RFDC `c2r` mode with the paired DAC converter enabled for I/Q-to-real DUC.

Each YAML config can set `project_name`, `bitstream_name`, `cir_fifo_depth`, RFDC TX/RX chain port mapping, RFDC property overrides, and output-copy settings. RF ports use RFSoC4x2 board names: `ADC_A`, `ADC_B`, `ADC_C`, `ADC_D`, `DAC_A`, and `DAC_B`.

Generated Tcl includes `copy_cir_sounder_outputs`, which copies `${bitstream_name}.bit` and `${bitstream_name}.hwh` to `outputs.directory` after `write_bitstream` has completed. The Python generator also writes `xrfdc_utils.py` into `outputs.directory` when `copy_xrfdc_utils: true`; place it next to the PYNQ `cir_sounder.py` so the runtime RFDC mixer and center-frequency setup matches the YAML. Use `jobs: auto` to emit Tcl that uses the host CPU count minus two for Vivado run parallelism.

To emit synthesis, implementation, and `write_bitstream` launch commands directly into the generated Tcl, pass `--run-bitstream`:
```bash
./generate_cir_sounder.py --config configs/cir_default.yml --run-bitstream
```

## Source Layout
Checked-in source files are kept outside the generated Vivado project tree:

- `rtl/`: Verilog sources
- `constraints/`: XDC constraints
- `sim/`: simulation sources and waveform config
- `ip_repo/`: local packaged IP

Generated Vivado output such as `cir_sounder.tcl`, `cir_sounder/`, `cir_sounder.srcs/`, `cir_sounder.sim/`, `build/`, and `.dcp` checkpoints are ignored.

## Contributing and Support
Want to contribute? Great! Please email info@houdini-sdr.org 

## Documentation
Other community resources can be found at the 
* [Houdini Website](https://houdini-sdr.org)  
* [Houdini Wiki](https://wiki.houdini-sdr.org)

## License
[Houdini open source license](license.md)

## Acknowledgment
Houdini is supported by National Science Foundation Grant No. CNS-2346550
