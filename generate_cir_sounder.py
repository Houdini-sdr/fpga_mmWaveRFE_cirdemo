#!/usr/bin/env python3
"""Generate the CIR sounder Vivado Tcl from a YAML configuration."""

from __future__ import annotations

import argparse
import pprint
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError as exc:  # pragma: no cover - exercised only on missing dependency
    raise SystemExit("ERROR: PyYAML is required. Install python3-yaml or pyyaml.") from exc


REPO_ROOT = Path(__file__).resolve().parent
TEMPLATE = REPO_ROOT / "templates" / "cir_sounder.tcl.in"
DEFAULT_CONFIG = REPO_ROOT / "configs" / "cir_default.yml"
DEFAULT_OUTPUT = REPO_ROOT / "cir_sounder.tcl"
RFDC_PROPERTY_RE = re.compile(r"^[A-Za-z0-9_]+$")
DAC_REF_TILE = 2
ADC_REF_TILE = 2


@dataclass(frozen=True)
class RFPort:
    name: str
    kind: str
    tile: int
    channel: int
    pair_slice: str
    axis: str
    pair_axis: str
    analog_port: str

    @property
    def slice_id(self) -> str:
        return f"{self.tile}{self.channel}"

    @property
    def pair_slice_id(self) -> str:
        return self.pair_slice


# RFSoC4x2 board labels from dev_references/RFSoC_RM_A6.pdf and motifpga presets.
# Vivado/xrfdc tile numbers are 0/2; ADC_A/B and DAC_A are on tile 2,
# while ADC_C/D and DAC_B are on tile 0.
RF_PORTS = {
    "ADC_A": RFPort("ADC_A", "adc", 2, 2, "23", "m22_axis", "m23_axis", "vin2_23"),
    "ADC_B": RFPort("ADC_B", "adc", 2, 0, "21", "m20_axis", "m21_axis", "vin2_01"),
    "ADC_C": RFPort("ADC_C", "adc", 0, 2, "03", "m02_axis", "m03_axis", "vin0_23"),
    "ADC_D": RFPort("ADC_D", "adc", 0, 0, "01", "m00_axis", "m01_axis", "vin0_01"),
    "DAC_A": RFPort("DAC_A", "dac", 2, 0, "22", "s20_axis", "s22_axis", "vout20"),
    "DAC_B": RFPort("DAC_B", "dac", 0, 0, "02", "s00_axis", "s02_axis", "vout00"),
}

RFDC_MODES = {"iq", "c2r", "r2c", "real"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate cir_sounder.tcl from configs/*.yml."
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_CONFIG,
        help=f"YAML config file. Default: {DEFAULT_CONFIG}",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Generated Tcl path. Overrides generated_tcl in the config.",
    )
    run_group = parser.add_mutually_exclusive_group()
    run_group.add_argument(
        "--run-bitstream",
        action="store_true",
        help="Emit Tcl commands that launch synth_1 and impl_1 through write_bitstream.",
    )
    run_group.add_argument(
        "--no-run-bitstream",
        action="store_true",
        help="Do not emit synth/implementation launch commands.",
    )
    parser.add_argument(
        "--jobs",
        help="Vivado job count for --run-bitstream: positive integer or auto. Overrides outputs.jobs.",
    )
    parser.add_argument(
        "--generate-only",
        action="store_true",
        help="Only write the Tcl file; do not run Vivado to source it.",
    )
    parser.add_argument(
        "--vivado",
        default="vivado",
        help="Vivado executable to run after generating Tcl. Default: vivado.",
    )
    return parser.parse_args()


def load_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict):
        raise ValueError(f"{path} must contain a YAML mapping.")
    return data


def as_mapping(value: Any, name: str) -> dict[str, Any]:
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise ValueError(f"{name} must be a mapping.")
    return value


def as_list(value: Any, name: str) -> list[Any]:
    if value is None:
        return []
    if not isinstance(value, list):
        raise ValueError(f"{name} must be a list.")
    return value


def tcl_quote(value: Any) -> str:
    text = str(value)
    replacements = {
        "\\": "\\\\",
        '"': '\\"',
        "$": "\\$",
        "[": "\\[",
        "]": "\\]",
        "\n": "\\n",
        "\r": "\\r",
    }
    return '"' + "".join(replacements.get(ch, ch) for ch in text) + '"'


def tcl_comment(value: Any) -> str:
    return str(value).replace("\r", " ").replace("\n", " ")


def display_path(path: Path | None) -> str:
    if path is None:
        return "<in-memory config>"
    try:
        return path.resolve().relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def tcl_value(value: Any) -> str:
    if isinstance(value, bool):
        text = "true" if value else "false"
    else:
        text = str(value)
    if any(ch in text for ch in "{}\n\r"):
        return tcl_quote(text)
    return "{" + text + "}"


def normalize_jobs(value: Any) -> str:
    text = str(value).strip().lower()
    if text == "auto":
        return "auto"
    try:
        jobs = int(text)
    except ValueError as exc:
        raise ValueError("Vivado jobs must be a positive integer or 'auto'.") from exc
    if jobs <= 0:
        raise ValueError(f"Vivado jobs must be positive, got {jobs}.")
    return str(jobs)


def render_jobs_setting(value: Any) -> tuple[list[str], str]:
    jobs = normalize_jobs(value)
    if jobs != "auto":
        return [], jobs

    lines = [
        "proc cir_sounder_auto_jobs {} {",
        "  set ncpu 1",
        "  if { ![catch {exec nproc} result] } {",
        "    set ncpu [string trim $result]",
        "  } elseif { [info exists ::env(NUMBER_OF_PROCESSORS)] } {",
        "    set ncpu $::env(NUMBER_OF_PROCESSORS)",
        "  } elseif { ![catch {exec sysctl -n hw.ncpu} result] } {",
        "    set ncpu [string trim $result]",
        "  }",
        "  if { ![string is integer -strict $ncpu] || $ncpu < 1 } {",
        "    set ncpu 1",
        "  }",
        "  set jobs [expr {$ncpu - 2}]",
        "  if { $jobs < 1 } {",
        "    set jobs 1",
        "  }",
        "  return $jobs",
        "}",
        "set _xil_vivado_jobs_ [cir_sounder_auto_jobs]",
        "puts \"INFO: Using $_xil_vivado_jobs_ Vivado jobs.\"",
    ]
    return lines, "$_xil_vivado_jobs_"


def normalize_mode(value: Any, field: str) -> str:
    mode = str(value).strip().lower()
    if mode not in RFDC_MODES:
        raise ValueError(f"{field} has unsupported mode '{value}'.")
    return mode


def normalize_property(name: Any) -> str:
    key = str(name).strip()
    if key.startswith("CONFIG."):
        key = key[len("CONFIG.") :]
    if not RFDC_PROPERTY_RE.match(key):
        raise ValueError(f"Invalid RFDC property '{name}'.")
    return key


def normalize_scalar(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float, str)):
        return str(value)
    raise ValueError(f"RFDC property values must be scalar, got {type(value).__name__}.")


def positive_int(value: Any, field: str) -> int:
    try:
        result = int(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{field} must be an integer, got {value!r}.") from exc
    if result <= 0:
        raise ValueError(f"{field} must be positive, got {result}.")
    return result


def vivado_nyquist_zone(value: Any, field: str) -> int:
    zone = positive_int(value, field)
    if zone not in (1, 2):
        raise ValueError(f"{field} must be 1 or 2, got {zone}.")
    return zone - 1


def get_port(name: Any, kind: str, field: str) -> RFPort:
    key = str(name).strip().upper()
    if key not in RF_PORTS:
        raise ValueError(f"{field} references unknown RFSoC4x2 port '{name}'.")
    port = RF_PORTS[key]
    if port.kind != kind:
        raise ValueError(f"{field} must name a {kind.upper()} port, got {name}.")
    return port


def add_override(overrides: dict[str, str], key: str, value: Any) -> None:
    overrides[normalize_property(key)] = normalize_scalar(value)


def dac_c2r_uses_pair(tx: dict[str, Any]) -> bool:
    data_format = str(tx.get("data_format", "real_interleaved")).strip().lower().replace("-", "_")
    return bool(tx.get("use_pair", False)) or data_format in {"paired_iq", "separate_iq", "iq_pair"}


def add_dac_c2r_overrides(overrides: dict[str, str], tx: dict[str, Any], port: RFPort) -> None:
    interpolation = tx.get("interpolation", 2)
    data_width = tx.get("data_width", 16)
    mixer_mode = tx.get("mixer_mode", 0)  # Runtime xrfdc programs C2R/fine NCO.
    mixer_type = tx.get("mixer_type", 2)  # Fine mixer for runtime NCO center-frequency control.
    use_pair = dac_c2r_uses_pair(tx)

    slice_ids = (port.slice_id, port.pair_slice_id) if use_pair else (port.slice_id,)
    for slice_id in slice_ids:
        add_override(overrides, f"DAC_Slice{slice_id}_Enable", True)
        add_override(overrides, f"DAC_Interpolation_Mode{slice_id}", interpolation)
        add_override(overrides, f"DAC_Data_Width{slice_id}", data_width)
        add_override(overrides, f"DAC_Mixer_Mode{slice_id}", mixer_mode)
        add_override(overrides, f"DAC_Mixer_Type{slice_id}", mixer_type)

        if use_pair:
            add_override(overrides, f"DAC_Data_Type{slice_id}", 1)
        elif "data_type" in tx:
            add_override(overrides, f"DAC_Data_Type{slice_id}", tx["data_type"])

    if "coarse_mixer_freq" in tx:
        add_override(overrides, f"DAC_Coarse_Mixer_Freq{port.slice_id}", tx["coarse_mixer_freq"])
    if "nyquist_zone" in tx:
        zone = vivado_nyquist_zone(tx["nyquist_zone"], "rfdc.tx.nyquist_zone")
        for slice_id in slice_ids:
            add_override(overrides, f"DAC_Nyquist{slice_id}", zone)


def add_adc_r2c_overrides(overrides: dict[str, str], rx: dict[str, Any], port: RFPort) -> None:
    decimation = rx.get("decimation", 2)
    data_width = rx.get("data_width", 8)
    mixer_mode = rx.get("mixer_mode", 2)  # ADC design-time R2C.
    mixer_type = rx.get("mixer_type", 2)  # Fine mixer.

    for slice_id in (port.slice_id, port.pair_slice_id):
        add_override(overrides, f"ADC_Slice{slice_id}_Enable", True)
        add_override(overrides, f"ADC_Decimation_Mode{slice_id}", decimation)
        add_override(overrides, f"ADC_Data_Width{slice_id}", data_width)
        add_override(overrides, f"ADC_Data_Type{slice_id}", 1)
        add_override(overrides, f"ADC_Mixer_Mode{slice_id}", mixer_mode)
        add_override(overrides, f"ADC_Mixer_Type{slice_id}", mixer_type)

    if "coarse_mixer_freq" in rx:
        for slice_id in (port.slice_id, port.pair_slice_id):
            add_override(overrides, f"ADC_Coarse_Mixer_Freq{slice_id}", rx["coarse_mixer_freq"])
    if "nyquist_zone" in rx:
        for slice_id in (port.slice_id, port.pair_slice_id):
            add_override(
                overrides,
                f"ADC_Nyquist{slice_id}",
                vivado_nyquist_zone(rx["nyquist_zone"], "rfdc.rx_chains[].nyquist_zone"),
            )


def add_iq_dac_overrides(overrides: dict[str, str], ports: tuple[RFPort, RFPort]) -> None:
    for port in ports:
        add_override(overrides, f"DAC_Coarse_Mixer_Freq{port.slice_id}", 0)


def add_iq_adc_overrides(overrides: dict[str, str], ports: tuple[RFPort, RFPort]) -> None:
    for port in ports:
        add_override(overrides, f"ADC_Coarse_Mixer_Freq{port.slice_id}", 0)


def connect_axis(
    net_name: str,
    left_pin: str,
    right_pin: str,
    *,
    debug_pin: str | None = None,
    debug_slot: int | None = None,
) -> list[str]:
    lines = [
        f"  connect_bd_intf_net -intf_net {net_name} "
        f"[get_bd_intf_pins {left_pin}] [get_bd_intf_pins {right_pin}]"
    ]
    if debug_slot is not None:
        if debug_pin is None:
            debug_pin = left_pin
        lines.extend(
            [
                f"  connect_bd_intf_net -intf_net [get_bd_intf_nets {net_name}] "
                f"[get_bd_intf_pins {debug_pin}] "
                f"[get_bd_intf_pins system_ila_0/SLOT_{debug_slot}_AXIS]",
                f"  set_property HDL_ATTRIBUTE.DEBUG {{true}} [get_bd_intf_nets {net_name}]",
            ]
        )
    return lines


def render_stream_connections(
    rfdc: dict[str, Any],
    overrides: dict[str, str],
    extra_stream_clk_pins: list[str],
    extra_stream_reset_pins: list[str],
) -> str:
    lines: list[str] = []
    tx = as_mapping(rfdc.get("tx"), "rfdc.tx")
    tx_mode = normalize_mode(tx.get("mode", "iq"), "rfdc.tx.mode")

    if tx_mode == "iq":
        i_port = get_port(tx.get("i_port", "DAC_A"), "dac", "rfdc.tx.i_port")
        q_port = get_port(tx.get("q_port", "DAC_B"), "dac", "rfdc.tx.q_port")
        if i_port == q_port:
            raise ValueError(f"rfdc.tx {tx_mode} mode requires distinct i_port and q_port.")
        add_iq_dac_overrides(overrides, (i_port, q_port))
        lines.extend(
            connect_axis(
                "CIR_Extract_1x1_Tx_t_0_I",
                "CIR_Extract_1x1_Tx_t_0/I",
                f"usp_rf_data_converter_0/{i_port.axis}",
                debug_pin="CIR_Extract_1x1_Tx_t_0/I",
                debug_slot=int(tx.get("i_debug_slot", 0)),
            )
        )
        lines.extend(
            connect_axis(
                "CIR_Extract_1x1_Tx_t_0_Q",
                "CIR_Extract_1x1_Tx_t_0/Q",
                f"usp_rf_data_converter_0/{q_port.axis}",
                debug_pin="CIR_Extract_1x1_Tx_t_0/Q",
                debug_slot=int(tx.get("q_debug_slot", 3)),
            )
        )
    elif tx_mode == "c2r":
        rf_port = get_port(tx.get("rf_port", "DAC_A"), "dac", "rfdc.tx.rf_port")
        sample_width = positive_int(tx.get("sample_width", 16), "rfdc.tx.sample_width")
        data_width = positive_int(tx.get("data_width", 16), "rfdc.tx.data_width")
        samples_per_stream = positive_int(
            tx.get("samples_per_stream", data_width // 2),
            "rfdc.tx.samples_per_stream",
        )
        if data_width != 2 * samples_per_stream:
            raise ValueError(
                "rfdc.tx.data_width must be twice rfdc.tx.samples_per_stream "
                "for c2r interleaved I/Q mode."
            )
        if sample_width * samples_per_stream != 128:
            raise ValueError(
                "rfdc.tx c2r currently expects sample_width * samples_per_stream "
                "to match the 128-bit I and Q outputs of CIR_Extract_1x1_Tx_top."
            )
        interleaver = str(tx.get("interleaver", "tx_iq_interleaver"))
        add_dac_c2r_overrides(overrides, tx, rf_port)
        extra_stream_clk_pins.append(f"[get_bd_pins {interleaver}/aclk]")
        extra_stream_reset_pins.append(f"[get_bd_pins {interleaver}/aresetn]")
        lines.extend(
            [
                "  # Create TX IQ interleaver for RFDC DAC C2R mode.",
                f"  set {interleaver} [ create_bd_cell -type module -reference axis_iq_interleaver {interleaver} ]",
                f"  set_property -dict [ list CONFIG.SAMPLE_WIDTH {{{sample_width}}} CONFIG.SAMPLES_PER_STREAM {{{samples_per_stream}}} ] ${interleaver}",
            ]
        )
        lines.extend(
            connect_axis(
                "CIR_Extract_1x1_Tx_t_0_I",
                "CIR_Extract_1x1_Tx_t_0/I",
                f"{interleaver}/s_axis_i",
                debug_pin="CIR_Extract_1x1_Tx_t_0/I",
                debug_slot=int(tx.get("i_debug_slot", 0)),
            )
        )
        lines.extend(
            connect_axis(
                "CIR_Extract_1x1_Tx_t_0_Q",
                "CIR_Extract_1x1_Tx_t_0/Q",
                f"{interleaver}/s_axis_q",
                debug_pin="CIR_Extract_1x1_Tx_t_0/Q",
                debug_slot=int(tx.get("q_debug_slot", 3)),
            )
        )
        lines.extend(
            connect_axis(
                f"{interleaver}_M_AXIS",
                f"{interleaver}/m_axis",
                f"usp_rf_data_converter_0/{rf_port.axis}",
            )
        )
    elif tx_mode == "real":
        rf_port = get_port(tx.get("rf_port", "DAC_A"), "dac", "rfdc.tx.rf_port")
        source = str(tx.get("source", "I")).strip().upper()
        if source not in {"I", "Q"}:
            raise ValueError("rfdc.tx.source must be I or Q for real mode.")
        debug_slot = tx.get("debug_slot", 0 if source == "I" else 3)
        lines.extend(
            connect_axis(
                f"CIR_Extract_1x1_Tx_t_0_{source}",
                f"CIR_Extract_1x1_Tx_t_0/{source}",
                f"usp_rf_data_converter_0/{rf_port.axis}",
                debug_pin=f"CIR_Extract_1x1_Tx_t_0/{source}",
                debug_slot=int(debug_slot),
            )
        )
    else:
        raise ValueError(f"Unsupported TX mode '{tx_mode}'.")

    rx_chains = as_list(rfdc.get("rx_chains"), "rfdc.rx_chains")
    for index, item in enumerate(rx_chains):
        rx = as_mapping(item, f"rfdc.rx_chains[{index}]")
        core = str(rx.get("core", f"CIR_Extract_1x1_top_{index}"))
        mode = normalize_mode(rx.get("mode", "iq"), f"rfdc.rx_chains[{index}].mode")
        debug_i = rx.get("i_debug_slot", 2 if index == 0 else None)
        debug_q = rx.get("q_debug_slot", 4 if index == 0 else None)

        if mode == "iq":
            i_port = get_port(rx.get("i_port"), "adc", f"rfdc.rx_chains[{index}].i_port")
            q_port = get_port(rx.get("q_port"), "adc", f"rfdc.rx_chains[{index}].q_port")
            if i_port == q_port:
                raise ValueError(f"{core} {mode} mode requires distinct i_port and q_port.")
            add_iq_adc_overrides(overrides, (i_port, q_port))
            lines.extend(
                connect_axis(
                    f"usp_rf_data_converter_0_{i_port.axis}",
                    f"{core}/I",
                    f"usp_rf_data_converter_0/{i_port.axis}",
                    debug_pin=f"{core}/I",
                    debug_slot=None if debug_i is None else int(debug_i),
                )
            )
            lines.extend(
                connect_axis(
                    f"usp_rf_data_converter_0_{q_port.axis}",
                    f"{core}/Q",
                    f"usp_rf_data_converter_0/{q_port.axis}",
                    debug_pin=f"{core}/Q",
                    debug_slot=None if debug_q is None else int(debug_q),
                )
            )
        elif mode == "r2c":
            rf_port = get_port(rx.get("rf_port"), "adc", f"rfdc.rx_chains[{index}].rf_port")
            add_adc_r2c_overrides(overrides, rx, rf_port)
            lines.extend(
                connect_axis(
                    f"usp_rf_data_converter_0_{rf_port.axis}",
                    f"{core}/I",
                    f"usp_rf_data_converter_0/{rf_port.axis}",
                    debug_pin=f"{core}/I",
                    debug_slot=None if debug_i is None else int(debug_i),
                )
            )
            lines.extend(
                connect_axis(
                    f"usp_rf_data_converter_0_{rf_port.pair_axis}",
                    f"{core}/Q",
                    f"usp_rf_data_converter_0/{rf_port.pair_axis}",
                    debug_pin=f"{core}/Q",
                    debug_slot=None if debug_q is None else int(debug_q),
                )
            )
        else:
            raise ValueError(f"Unsupported RX mode '{mode}' for {core}.")

    return "\n".join(lines)


def render_overrides(overrides: dict[str, str]) -> str:
    if not overrides:
        return "  # No generated RFDC property overrides."

    lines = ["  # Generated RFDC property overrides from YAML.", "  set_property -dict [ list \\"]
    for key in sorted(overrides):
        lines.append(f"   CONFIG.{key} {tcl_value(overrides[key])} \\")
    lines.append(" ] $usp_rf_data_converter_0")
    return "\n".join(lines)


def render_output_copy(
    outputs: dict[str, Any],
    bitstream_name: str,
    *,
    run_bitstream_override: bool | None = None,
    jobs_override: Any | None = None,
) -> str:
    directory = outputs.get("directory", "")
    copy_bitstream = bool(outputs.get("copy_bitstream", bool(directory)))
    copy_hwh = bool(outputs.get("copy_hwh", bool(directory)))
    run_bitstream = bool(run_bitstream_override)
    jobs_lines, jobs_value = render_jobs_setting(
        outputs.get("jobs", "auto") if jobs_override is None else jobs_override
    )

    lines = [
        "# Optional artifact export generated from YAML.",
        f"set _xil_output_dir_ {tcl_quote(directory)}",
        f"set _xil_copy_bitstream_ {1 if copy_bitstream else 0}",
        f"set _xil_copy_hwh_ {1 if copy_hwh else 0}",
        "",
        "proc copy_cir_sounder_outputs {} {",
        "  global proj_dir _xil_proj_name_ _xil_bitstream_name_ _xil_output_dir_ _xil_copy_bitstream_ _xil_copy_hwh_",
        "  if { $_xil_output_dir_ eq \"\" } {",
        "    puts \"INFO: No output directory configured for bitstream/HWH copy.\"",
        "    return",
        "  }",
        "  file mkdir $_xil_output_dir_",
        "  set bit_src [file normalize \"$proj_dir/${_xil_proj_name_}.runs/impl_1/cir_sounder_wrapper.bit\"]",
        "  set hwh_src [file normalize \"$proj_dir/${_xil_proj_name_}.gen/sources_1/bd/cir_sounder/hw_handoff/cir_sounder.hwh\"]",
        "  if { $_xil_copy_bitstream_ } {",
        "    set bit_dst [file join $_xil_output_dir_ \"${_xil_bitstream_name_}.bit\"]",
        "    if { [file exists $bit_src] } {",
        "      file copy -force $bit_src $bit_dst",
        "      puts \"INFO: Copied bitstream to $bit_dst\"",
        "    } else {",
        "      puts \"WARNING: Bitstream not found at $bit_src\"",
        "    }",
        "  }",
        "  if { $_xil_copy_hwh_ } {",
        "    set hwh_dst [file join $_xil_output_dir_ \"${_xil_bitstream_name_}.hwh\"]",
        "    if { [file exists $hwh_src] } {",
        "      file copy -force $hwh_src $hwh_dst",
        "      puts \"INFO: Copied HWH to $hwh_dst\"",
        "    } else {",
        "      puts \"WARNING: HWH not found at $hwh_src\"",
        "    }",
        "  }",
        "}",
        "",
    ]

    if run_bitstream:
        lines.extend(
            jobs_lines
            + [
                "puts \"INFO: Launching synthesis, implementation, and write_bitstream.\"",
                f"launch_runs synth_1 -jobs {jobs_value}",
                "wait_on_run synth_1",
                f"launch_runs impl_1 -to_step write_bitstream -jobs {jobs_value}",
                "wait_on_run impl_1",
                "copy_cir_sounder_outputs",
            ]
        )
    elif copy_bitstream or copy_hwh:
        lines.append(
            "puts \"INFO: Output copy configured. Call copy_cir_sounder_outputs after write_bitstream completes.\""
        )
    else:
        lines.append("puts \"INFO: Output copy is disabled in this configuration.\"")

    return "\n".join(lines)


def parse_slice_id(slice_id: str) -> tuple[int, int]:
    if len(slice_id) != 2 or not slice_id.isdigit():
        raise ValueError(f"Unexpected RFDC slice id '{slice_id}'.")
    return int(slice_id[0]), int(slice_id[1])


def port_runtime_dict(port: RFPort) -> dict[str, Any]:
    pair_tile, pair_channel = parse_slice_id(port.pair_slice_id)
    # Vivado RFDC stream names use slice numbers such as m02_axis/m22_axis,
    # while the PYNQ xrfdc driver indexes the two dual-ADC blocks as 0/1.
    xrfdc_channel = port.channel
    xrfdc_pair_channel = pair_channel
    if port.kind == "adc":
        xrfdc_channel = port.channel // 2
        xrfdc_pair_channel = pair_channel // 2
    return {
        "name": port.name,
        "tile": port.tile,
        "channel": port.channel,
        "xrfdc_channel": xrfdc_channel,
        "slice": port.slice_id,
        "axis": port.axis,
        "pair_tile": pair_tile,
        "pair_channel": pair_channel,
        "xrfdc_pair_channel": xrfdc_pair_channel,
        "pair_slice": port.pair_slice_id,
        "pair_axis": port.pair_axis,
    }


def build_runtime_config(config: dict[str, Any], config_path: Path | None = None) -> dict[str, Any]:
    rfdc = as_mapping(config.get("rfdc"), "rfdc")
    tx = as_mapping(rfdc.get("tx"), "rfdc.tx")
    tx_mode = normalize_mode(tx.get("mode", "iq"), "rfdc.tx.mode")

    runtime_tx: dict[str, Any] = {"mode": tx_mode}
    active_dac_tiles = 0
    active_adc_tiles = 0

    if tx_mode == "iq":
        ports = [
            get_port(tx.get("i_port", "DAC_A"), "dac", "rfdc.tx.i_port"),
            get_port(tx.get("q_port", "DAC_B"), "dac", "rfdc.tx.q_port"),
        ]
        runtime_tx["ports"] = [port_runtime_dict(port) for port in ports]
        for port in ports:
            active_dac_tiles |= 1 << port.tile
    elif tx_mode == "c2r":
        port = get_port(tx.get("rf_port", "DAC_A"), "dac", "rfdc.tx.rf_port")
        runtime_tx.update(
            {
                "port": port_runtime_dict(port),
                "interpolation": int(tx.get("interpolation", 2)),
                "data_width": int(tx.get("data_width", 16)),
                "data_format": str(tx.get("data_format", "real_interleaved")),
                "use_pair": dac_c2r_uses_pair(tx),
                "mixer_mode": int(tx.get("mixer_mode", 0)),
                "mixer_type": int(tx.get("mixer_type", 2)),
                "center_frequency_mhz": float(tx.get("center_frequency_mhz", 0.0)),
                "nyquist_zone": int(tx.get("nyquist_zone", 0)),
            }
        )
        if "coarse_mixer_freq" in tx:
            runtime_tx["coarse_mixer_freq"] = int(tx["coarse_mixer_freq"])
        active_dac_tiles |= 1 << port.tile
    elif tx_mode == "real":
        port = get_port(tx.get("rf_port", "DAC_A"), "dac", "rfdc.tx.rf_port")
        runtime_tx["port"] = port_runtime_dict(port)
        active_dac_tiles |= 1 << port.tile

    runtime_rx: list[dict[str, Any]] = []
    for index, item in enumerate(as_list(rfdc.get("rx_chains"), "rfdc.rx_chains")):
        rx = as_mapping(item, f"rfdc.rx_chains[{index}]")
        mode = normalize_mode(rx.get("mode", "iq"), f"rfdc.rx_chains[{index}].mode")
        chain: dict[str, Any] = {
            "name": str(rx.get("name", f"rx{index}")),
            "mode": mode,
            "core": str(rx.get("core", f"CIR_Extract_1x1_top_{index}")),
        }
        if mode == "iq":
            ports = [
                get_port(rx.get("i_port"), "adc", f"rfdc.rx_chains[{index}].i_port"),
                get_port(rx.get("q_port"), "adc", f"rfdc.rx_chains[{index}].q_port"),
            ]
            chain["ports"] = [port_runtime_dict(port) for port in ports]
            for port in ports:
                active_adc_tiles |= 1 << port.tile
        elif mode == "r2c":
            port = get_port(rx.get("rf_port"), "adc", f"rfdc.rx_chains[{index}].rf_port")
            chain.update(
                {
                    "port": port_runtime_dict(port),
                    "decimation": int(rx.get("decimation", 2)),
                    "mixer_mode": int(rx.get("mixer_mode", 2)),
                    "mixer_type": int(rx.get("mixer_type", 2)),
                    "center_frequency_mhz": float(rx.get("center_frequency_mhz", 0.0)),
                    "nyquist_zone": int(rx.get("nyquist_zone", 0)),
                }
            )
            active_adc_tiles |= 1 << port.tile
        runtime_rx.append(chain)

    clocks = as_mapping(rfdc.get("clocks"), "rfdc.clocks")
    mts = as_mapping(rfdc.get("mts"), "rfdc.mts")
    default_dac_ref = DAC_REF_TILE if active_dac_tiles & (1 << DAC_REF_TILE) else 0
    default_adc_ref = ADC_REF_TILE if active_adc_tiles & (1 << ADC_REF_TILE) else 0
    return {
        "project_name": str(config.get("project_name", "cir_sounder")),
        "bitstream_name": str(config.get("bitstream_name", config.get("project_name", "cir_sounder"))).removesuffix(".bit"),
        "config": display_path(config_path),
        "ref_clocks": {
            "lmk_freq": float(clocks.get("lmk_freq", 245.76)),
            "lmx_freq": float(clocks.get("lmx_freq", 491.52)),
        },
        "mts": {
            "dac_ref_tile": int(mts.get("dac_ref_tile", default_dac_ref)),
            "adc_ref_tile": int(mts.get("adc_ref_tile", default_adc_ref)),
            "dac_tiles": int(mts.get("dac_tiles", active_dac_tiles)),
            "adc_tiles": int(mts.get("adc_tiles", active_adc_tiles)),
        },
        "tx": runtime_tx,
        "rx_chains": runtime_rx,
    }


RFDC_DIAGNOSTIC_HELPERS = r'''
def _read_optional_attr(obj: Any, attr: str) -> tuple[bool, Any]:
    try:
        return True, getattr(obj, attr)
    except AttributeError:
        return False, None
    except Exception as exc:
        return True, {"error": f"{type(exc).__name__}: {exc}"}


def _read_dict_attr(obj: Any, attr: str) -> Any:
    present, value = _read_optional_attr(obj, attr)
    if not present:
        return None
    if isinstance(value, dict) and "error" in value:
        return value
    try:
        return dict(value)
    except Exception as exc:
        return {"error": f"{type(exc).__name__}: {exc}"}


def _read_clock_tree_lock(target: Any) -> Optional[int]:
    clock_tree = getattr(target, "clockTreeMTS", None)
    clk_wiz = getattr(clock_tree, "clk_wiz_0", None)
    if clk_wiz is None:
        return None
    try:
        return int(clk_wiz.read(0x0004))
    except Exception:
        pass
    mmio = getattr(clk_wiz, "mmio", None)
    if mmio is None:
        return None
    try:
        return int(mmio.read(0x0004))
    except Exception:
        return None


def _tile_by_index(rfdc: Any, kind: str, tile_idx: int) -> Any:
    tiles = rfdc.dac_tiles if kind == "dac" else rfdc.adc_tiles
    return tiles[int(tile_idx)]


def _tile_state(rfdc: Any, kind: str, tile_idx: int) -> Dict[str, Any]:
    state: Dict[str, Any] = {"kind": kind, "tile": int(tile_idx)}
    try:
        tile = _tile_by_index(rfdc, kind, tile_idx)
    except Exception as exc:
        state["error"] = f"{type(exc).__name__}: {exc}"
        return state

    for attr in ("PLLLockStatus", "TileStatus", "FIFOStatus"):
        present, value = _read_optional_attr(tile, attr)
        if present:
            state[attr] = value
    return state


def _active_tile_indices(mask: int) -> list[int]:
    return [idx for idx in range(4) if (int(mask) >> idx) & 0x1]


def _block_state(rfdc: Any, kind: str, port: Dict[str, Any], role: str) -> Dict[str, Any]:
    xrfdc_channel = int(port.get("xrfdc_channel", port["channel"]))
    state: Dict[str, Any] = {
        "kind": kind,
        "role": role,
        "name": port.get("name"),
        "tile": int(port["tile"]),
        "channel": int(port["channel"]),
        "xrfdc_channel": xrfdc_channel,
        "slice": port.get("slice"),
        "axis": port.get("axis"),
    }
    try:
        tile = _tile_by_index(rfdc, kind, int(port["tile"]))
        block = tile.blocks[xrfdc_channel]
    except Exception as exc:
        state["error"] = f"{type(exc).__name__}: {exc}"
        return state

    for attr in ("NyquistZone", "BlockStatus"):
        present, value = _read_optional_attr(block, attr)
        if present:
            state[attr] = value
    if kind == "dac":
        present, value = _read_optional_attr(block, "InterpolationFactor")
        if present:
            state["InterpolationFactor"] = value
    else:
        present, value = _read_optional_attr(block, "DecimationFactor")
        if present:
            state["DecimationFactor"] = value
    mixer = _read_dict_attr(block, "MixerSettings")
    if mixer is not None:
        state["MixerSettings"] = mixer
    return state


def _pair_port(port: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "name": f"{port.get('name', 'port')}_pair",
        "tile": int(port["pair_tile"]),
        "channel": int(port["pair_channel"]),
        "xrfdc_channel": int(port.get("xrfdc_pair_channel", port["pair_channel"])),
        "slice": port.get("pair_slice"),
        "axis": port.get("pair_axis"),
    }


def _read_mts_state(rfdc: Any) -> Dict[str, Any]:
    result: Dict[str, Any] = {"expected": dict(CONFIG["mts"]), "actual": {}}
    for cfg_name in ("mts_dac_config", "mts_adc_config"):
        cfg = getattr(rfdc, cfg_name, None)
        if cfg is None:
            continue
        cfg_state: Dict[str, Any] = {}
        for attr in ("Tiles", "RefTile", "SysRef_Enable", "Target_Latency"):
            present, value = _read_optional_attr(cfg, attr)
            if present:
                cfg_state[attr] = value
        result["actual"][cfg_name] = cfg_state
    return result


def read_rfdc_state(target: Any) -> Dict[str, Any]:
    """Read actual RFDC runtime state from xrfdc, not just host config registers."""
    state: Dict[str, Any] = {
        "driver_bound": False,
        "clock_tree_lock": _read_clock_tree_lock(target),
        "expected": {
            "mts": dict(CONFIG["mts"]),
            "tx": dict(CONFIG["tx"]),
            "rx_chains": list(CONFIG.get("rx_chains", [])),
        },
    }
    try:
        rfdc = _rfdc_from(target)
    except Exception as exc:
        state["error"] = f"{type(exc).__name__}: {exc}"
        return state

    state["driver_bound"] = hasattr(rfdc, "dac_tiles") and hasattr(rfdc, "adc_tiles")
    if not state["driver_bound"]:
        state["error"] = "RFDC driver is not bound; import xrfdc before loading the overlay."
        return state

    mts = CONFIG["mts"]
    state["mts"] = _read_mts_state(rfdc)
    state["tiles"] = {
        "dac": [_tile_state(rfdc, "dac", idx) for idx in _active_tile_indices(int(mts["dac_tiles"]))],
        "adc": [_tile_state(rfdc, "adc", idx) for idx in _active_tile_indices(int(mts["adc_tiles"]))],
    }

    tx = CONFIG["tx"]
    tx_state: Dict[str, Any] = {"mode": tx.get("mode")}
    if "port" in tx:
        tx_state["block"] = _block_state(rfdc, "dac", tx["port"], "tx")
        if bool(tx.get("use_pair", False)) and "pair_tile" in tx["port"] and "pair_channel" in tx["port"]:
            tx_state["pair_block"] = _block_state(rfdc, "dac", _pair_port(tx["port"]), "tx_pair")
    state["tx"] = tx_state

    rx_states = []
    for chain in CONFIG.get("rx_chains", []):
        chain_state: Dict[str, Any] = {"name": chain.get("name"), "mode": chain.get("mode"), "ports": []}
        for port in chain.get("ports", []):
            chain_state["ports"].append(_block_state(rfdc, "adc", port, str(chain.get("name", "rx"))))
        if "port" in chain:
            chain_state["ports"].append(_block_state(rfdc, "adc", chain["port"], str(chain.get("name", "rx"))))
        rx_states.append(chain_state)
    state["rx_chains"] = rx_states
    return state


def _add_check(checks: list[Dict[str, Any]], name: str, ok: bool, actual: Any, expected: Any) -> None:
    checks.append({"name": name, "ok": bool(ok), "actual": actual, "expected": expected})


def _has_error(value: Any) -> bool:
    return isinstance(value, dict) and "error" in value


def _block_readback_status(block_state: Dict[str, Any], kind: str) -> tuple[bool, Any]:
    if "error" in block_state:
        return False, block_state["error"]
    required = ["NyquistZone", "BlockStatus", "MixerSettings"]
    required.append("InterpolationFactor" if kind == "dac" else "DecimationFactor")
    for key in required:
        if key not in block_state:
            return False, f"missing {key}"
        value = block_state[key]
        if _has_error(value):
            return False, value
    return True, "readable"


def validate_rfdc_state(
    target: Any,
    *,
    center_frequency_mhz: Optional[float] = None,
    freq_tolerance_mhz: float = 0.001,
    verbose: bool = True,
) -> Dict[str, Any]:
    """Read RFDC state and compare critical runtime values against CONFIG."""
    state = read_rfdc_state(target)
    checks: list[Dict[str, Any]] = []
    _add_check(checks, "xrfdc driver bound", bool(state.get("driver_bound")), state.get("driver_bound"), True)

    clock_lock = state.get("clock_tree_lock")
    if clock_lock is not None:
        _add_check(checks, "clockTreeMTS locked", int(clock_lock) == 1, clock_lock, 1)

    for kind in ("dac", "adc"):
        for tile in state.get("tiles", {}).get(kind, []):
            lock = tile.get("PLLLockStatus")
            _add_check(
                checks,
                f"{kind.upper()} tile {tile.get('tile')} PLL locked",
                (not _has_error(lock)) and bool(lock),
                lock,
                "nonzero",
            )

    tx = CONFIG["tx"]
    tx_block = state.get("tx", {}).get("block", {})
    readable, actual = _block_readback_status(tx_block, "dac")
    _add_check(checks, "TX DAC block readable", readable, actual, "readable")
    nyquist = tx.get("nyquist_zone")
    if nyquist is not None:
        actual = tx_block.get("NyquistZone")
        _add_check(checks, "TX DAC NyquistZone", actual == int(nyquist), actual, int(nyquist))
    if "interpolation" in tx:
        actual = tx_block.get("InterpolationFactor")
        _add_check(checks, "TX DAC interpolation", actual == int(tx["interpolation"]), actual, int(tx["interpolation"]))

    mixer = tx_block.get("MixerSettings")
    if isinstance(mixer, dict) and not _has_error(mixer):
        xrfdc = _xrfdc()
        expected_freq = float(tx.get("center_frequency_mhz", 0.0) if center_frequency_mhz is None else center_frequency_mhz)
        actual_freq = mixer.get("Freq")
        freq_ok = isinstance(actual_freq, (int, float)) and abs(float(actual_freq) - expected_freq) <= float(freq_tolerance_mhz)
        _add_check(checks, "TX DAC mixer Freq MHz", freq_ok, actual_freq, expected_freq)
        _add_check(checks, "TX DAC mixer mode C2R", mixer.get("MixerMode") == xrfdc.MIXER_MODE_C2R, mixer.get("MixerMode"), xrfdc.MIXER_MODE_C2R)
        expected_type = xrfdc.MIXER_TYPE_FINE if int(tx.get("mixer_type", 2)) == 2 else xrfdc.MIXER_TYPE_COARSE
        _add_check(checks, "TX DAC mixer type", mixer.get("MixerType") == expected_type, mixer.get("MixerType"), expected_type)
    else:
        _add_check(checks, "TX DAC MixerSettings readable", False, mixer, "dict")

    tx_pair = state.get("tx", {}).get("pair_block")
    if isinstance(tx_pair, dict):
        readable, actual = _block_readback_status(tx_pair, "dac")
        _add_check(checks, "TX DAC pair block readable", readable, actual, "readable")

    for chain in state.get("rx_chains", []):
        for port in chain.get("ports", []):
            readable, actual = _block_readback_status(port, "adc")
            name = (
                f"RX ADC {chain.get('name')}:{port.get('name')} "
                f"tile {port.get('tile')} xrfdc block {port.get('xrfdc_channel')} readable"
            )
            _add_check(checks, name, readable, actual, "readable")

    ok = all(check["ok"] for check in checks)
    report = {"ok": ok, "state": state, "checks": checks}
    if verbose:
        for check in checks:
            status = "OK" if check["ok"] else "FAIL"
            print(f"[{status}] {check['name']}: actual={check['actual']} expected={check['expected']}")
        print(f"RFDC validation: {'OK' if ok else 'FAIL'}")
    return report


def print_rfdc_state(target: Any, *, validate: bool = True) -> Dict[str, Any]:
    """Print a concise RFDC readback report and return the raw state/report."""
    if validate:
        report = validate_rfdc_state(target, verbose=False)
        state = report["state"]
    else:
        report = read_rfdc_state(target)
        state = report

    print("RFDC readback:")
    print(f"  driver_bound: {state.get('driver_bound')}")
    if state.get("clock_tree_lock") is not None:
        print(f"  clockTreeMTS lock: {state.get('clock_tree_lock')}")
    for kind in ("dac", "adc"):
        for tile in state.get("tiles", {}).get(kind, []):
            print(f"  {kind.upper()} tile {tile.get('tile')} PLLLockStatus: {tile.get('PLLLockStatus')}")
    tx_block = state.get("tx", {}).get("block", {})
    print(
        "  TX DAC "
        f"{tx_block.get('name')} tile={tx_block.get('tile')} slice={tx_block.get('slice')} "
        f"axis={tx_block.get('axis')} xrfdc_block={tx_block.get('xrfdc_channel')} "
        f"NyquistZone={tx_block.get('NyquistZone')} "
        f"Interpolation={tx_block.get('InterpolationFactor')}"
    )
    print(f"    MixerSettings: {tx_block.get('MixerSettings')}")
    print(f"    BlockStatus: {tx_block.get('BlockStatus')}")
    tx_pair = state.get("tx", {}).get("pair_block")
    if isinstance(tx_pair, dict):
        print(
            "  TX DAC pair "
            f"{tx_pair.get('name')} tile={tx_pair.get('tile')} slice={tx_pair.get('slice')} "
            f"axis={tx_pair.get('axis')} xrfdc_block={tx_pair.get('xrfdc_channel')} "
            f"NyquistZone={tx_pair.get('NyquistZone')} "
            f"Interpolation={tx_pair.get('InterpolationFactor')}"
        )
        print(f"    MixerSettings: {tx_pair.get('MixerSettings')}")
        print(f"    BlockStatus: {tx_pair.get('BlockStatus')}")
    for chain in state.get("rx_chains", []):
        for port in chain.get("ports", []):
            print(
                "  RX ADC "
                f"{chain.get('name')}:{port.get('name')} tile={port.get('tile')} "
                f"slice={port.get('slice')} axis={port.get('axis')} xrfdc_block={port.get('xrfdc_channel')} "
                f"NyquistZone={port.get('NyquistZone')} Decimation={port.get('DecimationFactor')}"
            )
            print(f"    MixerSettings: {port.get('MixerSettings')}")
            print(f"    BlockStatus: {port.get('BlockStatus')}")
    if validate and isinstance(report, dict):
        for check in report["checks"]:
            status = "OK" if check["ok"] else "FAIL"
            print(f"  [{status}] {check['name']}: actual={check['actual']} expected={check['expected']}")
        print(f"  validation: {'OK' if report['ok'] else 'FAIL'}")
    return report
'''


def render_xrfdc_utils(config: dict[str, Any], config_path: Path | None = None) -> str:
    runtime = build_runtime_config(config, config_path)
    runtime_literal = pprint.pformat(runtime, indent=4, sort_dicts=True, width=100)
    return f'''"""Runtime RFDC configuration for the generated CIR sounder overlay.

This file is generated by generate_cir_sounder.py from {display_path(config_path)}.
Keep configuration changes in configs/*.yml and regenerate the artifacts.
"""

from __future__ import annotations

from typing import Any, Dict, Optional


CONFIG: Dict[str, Any] = {runtime_literal}


def configure_ref_clocks(xrfclk_module: Optional[Any] = None, *, verbose: bool = True) -> Dict[str, float]:
    """Program RFSoC4x2 LMK/LMX reference clocks for this overlay."""
    if xrfclk_module is None:
        import xrfclk as xrfclk_module  # type: ignore

    ref = CONFIG["ref_clocks"]
    xrfclk_module.set_ref_clks(lmk_freq=ref["lmk_freq"], lmx_freq=ref["lmx_freq"])
    if verbose:
        print(f"RF clocks: LMK={{ref['lmk_freq']}} MHz, LMX={{ref['lmx_freq']}} MHz")
    return dict(ref)


def _rfdc_from(target: Any) -> Any:
    if hasattr(target, "dac_tiles") and hasattr(target, "adc_tiles"):
        return target
    if hasattr(target, "xrfdc"):
        return target.xrfdc
    if hasattr(target, "usp_rf_data_converter_0"):
        return target.usp_rf_data_converter_0
    raise AttributeError("Could not find usp_rf_data_converter_0/xrfdc on target.")


def _xrfdc() -> Any:
    import xrfdc  # type: ignore

    return xrfdc


def _block(rfdc: Any, kind: str, port: Dict[str, Any]) -> Any:
    tiles = rfdc.dac_tiles if kind == "dac" else rfdc.adc_tiles
    return tiles[int(port["tile"])].blocks[int(port.get("xrfdc_channel", port["channel"]))]


def _pair_block(rfdc: Any, kind: str, port: Dict[str, Any]) -> Optional[Any]:
    tiles = rfdc.dac_tiles if kind == "dac" else rfdc.adc_tiles
    try:
        block_idx = int(port.get("xrfdc_pair_channel", port["pair_channel"]))
        return tiles[int(port["pair_tile"])].blocks[block_idx]
    except Exception:
        return None


def _apply_mts_config(rfdc: Any) -> None:
    mts = CONFIG["mts"]
    rfdc.mts_dac_config.RefTile = int(mts["dac_ref_tile"])
    rfdc.mts_adc_config.RefTile = int(mts["adc_ref_tile"])


def _tx_ports() -> list[Dict[str, Any]]:
    tx = CONFIG["tx"]
    ports: list[Dict[str, Any]] = []
    if "port" in tx:
        ports.append(tx["port"])
    ports.extend(tx.get("ports", []))
    if bool(tx.get("use_pair", False)) and "port" in tx:
        port = tx["port"]
        ports.append(
            {{
                "tile": int(port["pair_tile"]),
                "channel": int(port["pair_channel"]),
                "xrfdc_channel": int(port.get("xrfdc_pair_channel", port["pair_channel"])),
            }}
        )
    return ports


def _rx_ports() -> list[Dict[str, Any]]:
    ports: list[Dict[str, Any]] = []
    for chain in CONFIG.get("rx_chains", []):
        if "port" in chain:
            ports.append(chain["port"])
        ports.extend(chain.get("ports", []))
    return ports


def _setup_fifo(tile: Any, enable: bool) -> None:
    if hasattr(tile, "SetupFIFO"):
        tile.SetupFIFO(bool(enable))
    elif hasattr(tile, "SetupFIFOBoth"):
        tile.SetupFIFOBoth(bool(enable))


def setup_tile_fifos(target: Any, *, enable: bool = True, verbose: bool = True) -> Any:
    """Enable RFDC tile FIFOs for the generated TX/RX paths."""
    rfdc = _rfdc_from(target)
    dac_tiles = sorted({{int(port["tile"]) for port in _tx_ports()}})
    adc_tiles = sorted({{int(port["tile"]) for port in _rx_ports()}})

    for tile_idx in dac_tiles:
        _setup_fifo(rfdc.dac_tiles[tile_idx], enable)
        if verbose:
            print(f"DAC tile {{tile_idx}} FIFO {{'enabled' if enable else 'disabled'}}")
    for tile_idx in adc_tiles:
        _setup_fifo(rfdc.adc_tiles[tile_idx], enable)
        if verbose:
            print(f"ADC tile {{tile_idx}} FIFO {{'enabled' if enable else 'disabled'}}")
    return rfdc


def _set_nyquist(block: Any, zone: Optional[int]) -> None:
    if zone is not None:
        block.NyquistZone = int(zone)


def _configure_dac_c2r(rfdc: Any, center_frequency_mhz: Optional[float], *, verbose: bool) -> None:
    xrfdc = _xrfdc()
    tx = CONFIG["tx"]
    port = tx["port"]
    block = _block(rfdc, "dac", port)
    pair = _pair_block(rfdc, "dac", port) if bool(tx.get("use_pair", False)) else None
    freq = float(tx.get("center_frequency_mhz", 0.0) if center_frequency_mhz is None else center_frequency_mhz)
    nyquist = tx.get("nyquist_zone")

    _set_nyquist(block, nyquist)
    if pair is not None:
        _set_nyquist(pair, nyquist)

    settings = dict(block.MixerSettings)
    if int(tx.get("mixer_type", 2)) == 2:
        settings.update(
            {{
                "CoarseMixFreq": xrfdc.COARSE_MIX_BYPASS,
                "EventSource": xrfdc.EVNT_SRC_IMMEDIATE,
                "FineMixerScale": xrfdc.MIXER_SCALE_1P0,
                "Freq": freq,
                "MixerMode": xrfdc.MIXER_MODE_C2R,
                "MixerType": xrfdc.MIXER_TYPE_FINE,
                "PhaseOffset": 0.0,
            }}
        )
    else:
        settings.update(
            {{
                "EventSource": xrfdc.EVNT_SRC_IMMEDIATE,
                "Freq": 0.0,
                "MixerMode": xrfdc.MIXER_MODE_C2R,
                "MixerType": xrfdc.MIXER_TYPE_COARSE,
                "PhaseOffset": 0.0,
            }}
        )
        if "coarse_mixer_freq" in tx:
            settings["CoarseMixFreq"] = int(tx["coarse_mixer_freq"])

    block.MixerSettings = settings
    block.UpdateEvent(xrfdc.EVENT_MIXER)
    if pair is not None:
        pair.MixerSettings = settings
        pair.UpdateEvent(xrfdc.EVENT_MIXER)
    if verbose:
        print(
            "Configured TX DAC "
            f"{{port['name']}} tile={{port['tile']}} slice={{port.get('slice')}} "
            f"xrfdc_block={{port.get('xrfdc_channel', port['channel'])}} "
            f"mode=C2R center={{freq}} MHz nyquist={{nyquist}}"
        )


def _configure_adc_r2c(rfdc: Any, chain: Dict[str, Any], center_frequency_mhz: Optional[float], *, verbose: bool) -> None:
    xrfdc = _xrfdc()
    port = chain["port"]
    block = _block(rfdc, "adc", port)
    pair = _pair_block(rfdc, "adc", port)
    freq = float(chain.get("center_frequency_mhz", 0.0) if center_frequency_mhz is None else center_frequency_mhz)
    nyquist = chain.get("nyquist_zone")

    _set_nyquist(block, nyquist)
    if pair is not None:
        _set_nyquist(pair, nyquist)

    settings = dict(block.MixerSettings)
    settings.update(
        {{
            "CoarseMixFreq": xrfdc.COARSE_MIX_BYPASS,
            "EventSource": xrfdc.EVNT_SRC_IMMEDIATE,
            "FineMixerScale": xrfdc.MIXER_SCALE_1P0,
            "Freq": freq,
            "MixerMode": xrfdc.MIXER_MODE_R2C,
            "MixerType": xrfdc.MIXER_TYPE_FINE,
            "PhaseOffset": 0.0,
        }}
    )
    block.MixerSettings = settings
    block.UpdateEvent(xrfdc.EVENT_MIXER)
    if verbose:
        print(
            "Configured RX ADC "
            f"{{chain['name']}} {{port['name']}} tile={{port['tile']}} slice={{port.get('slice')}} "
            f"xrfdc_block={{port.get('xrfdc_channel', port['channel'])}} "
            f"mode=R2C center={{freq}} MHz nyquist={{nyquist}}"
        )


{RFDC_DIAGNOSTIC_HELPERS}


def configure_rfdc(target: Any, *, center_frequency_mhz: Optional[float] = None, verbose: bool = True) -> Any:
    """Apply runtime RFDC settings described by CONFIG to an Overlay or RFDC IP."""
    rfdc = _rfdc_from(target)
    _apply_mts_config(rfdc)

    tx = CONFIG["tx"]
    if tx.get("mode") == "c2r":
        _configure_dac_c2r(rfdc, center_frequency_mhz, verbose=verbose)

    for chain in CONFIG.get("rx_chains", []):
        if chain.get("mode") == "r2c":
            _configure_adc_r2c(rfdc, chain, center_frequency_mhz, verbose=verbose)

    setup_tile_fifos(rfdc, verbose=verbose)
    return rfdc


def set_center_frequency(target: Any, center_frequency_mhz: float, *, verbose: bool = True) -> Any:
    """Update the runtime RFDC mixer center frequency in MHz."""
    return configure_rfdc(target, center_frequency_mhz=center_frequency_mhz, verbose=verbose)
'''


def xrfdc_utils_output_path(config: dict[str, Any]) -> Path | None:
    outputs = as_mapping(config.get("outputs"), "outputs")
    if not bool(outputs.get("copy_xrfdc_utils", bool(outputs.get("directory", "")))):
        return None
    directory = outputs.get("directory", "")
    if not directory:
        return None
    filename = str(outputs.get("xrfdc_utils_name", "xrfdc_utils.py"))
    path = Path(str(directory)) / filename
    if not path.is_absolute():
        path = REPO_ROOT / path
    return path


def render_tcl(
    config: dict[str, Any],
    *,
    config_path: Path | None = None,
    run_bitstream_override: bool | None = None,
    jobs_override: Any | None = None,
) -> str:
    project_name = str(config.get("project_name", "cir_sounder"))
    bitstream_name = str(config.get("bitstream_name", project_name)).removesuffix(".bit")
    origin_dir = str(config.get("origin_dir", "."))
    fifo_depth = int(config.get("cir_fifo_depth", config.get("fifo_depth", 8192)))
    if fifo_depth <= 0:
        raise ValueError(f"cir_fifo_depth must be positive, got {fifo_depth}.")

    rfdc = as_mapping(config.get("rfdc"), "rfdc")
    overrides: dict[str, str] = {}
    extra_stream_clk_pins: list[str] = []
    extra_stream_reset_pins: list[str] = []
    stream_connections = render_stream_connections(
        rfdc,
        overrides,
        extra_stream_clk_pins,
        extra_stream_reset_pins,
    )
    for key, value in as_mapping(rfdc.get("properties"), "rfdc.properties").items():
        overrides[normalize_property(key)] = normalize_scalar(value)
    rfdc_override_tcl = render_overrides(overrides)
    output_copy_tcl = render_output_copy(
        as_mapping(config.get("outputs"), "outputs"),
        bitstream_name,
        run_bitstream_override=run_bitstream_override,
        jobs_override=jobs_override,
    )

    template = TEMPLATE.read_text(encoding="utf-8")
    replacements = {
        "@@CONFIG_PATH_COMMENT@@": tcl_comment(display_path(config_path)),
        "@@PROJECT_NAME_COMMENT@@": tcl_comment(project_name),
        "@@BITSTREAM_NAME_COMMENT@@": tcl_comment(bitstream_name),
        "@@ORIGIN_DIR_TCL@@": tcl_quote(origin_dir),
        "@@PROJECT_NAME_TCL@@": tcl_quote(project_name),
        "@@BITSTREAM_NAME_TCL@@": tcl_quote(bitstream_name),
        "@@CIR_FIFO_DEPTH@@": str(fifo_depth),
        "@@RFDC_OVERRIDE_TCL@@": rfdc_override_tcl,
        "@@RFDC_STREAM_CONNECTIONS_TCL@@": stream_connections,
        "@@RFDC_EXTRA_STREAM_CLK_PINS@@": "".join(f" {pin}" for pin in extra_stream_clk_pins),
        "@@RFDC_EXTRA_STREAM_RESET_PINS@@": "".join(f" {pin}" for pin in extra_stream_reset_pins),
        "@@OUTPUT_COPY_TCL@@": output_copy_tcl,
    }
    for marker, value in replacements.items():
        template = template.replace(marker, value)

    leftovers = sorted(set(re.findall(r"@@[A-Z0-9_]+@@", template)))
    if leftovers:
        raise ValueError(f"Template placeholders were not replaced: {', '.join(leftovers)}.")
    return template


def output_path(config: dict[str, Any], override: Path | None) -> Path:
    if override is not None:
        path = override
    else:
        path = Path(str(config.get("generated_tcl", DEFAULT_OUTPUT)))
    if not path.is_absolute():
        path = REPO_ROOT / path
    return path


def vivado_source_path(path: Path) -> str:
    try:
        return path.resolve().relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def run_vivado(vivado: str, tcl_path: Path) -> int:
    tcl_arg = vivado_source_path(tcl_path)
    cmd = [vivado, "-mode", "batch", "-source", tcl_arg]
    print(f"Running: {' '.join(cmd)}")
    return subprocess.run(cmd, cwd=REPO_ROOT).returncode


def main() -> int:
    args = parse_args()
    try:
        config_path = args.config
        if not config_path.is_absolute():
            config_path = REPO_ROOT / config_path
        config = load_yaml(config_path)
        if args.run_bitstream:
            run_bitstream_override = True
        elif args.no_run_bitstream:
            run_bitstream_override = False
        else:
            run_bitstream_override = None
        rendered = render_tcl(
            config,
            config_path=config_path,
            run_bitstream_override=run_bitstream_override,
            jobs_override=args.jobs,
        )
        out = output_path(config, args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(rendered, encoding="utf-8")
        xrfdc_utils_out = xrfdc_utils_output_path(config)
        if xrfdc_utils_out is not None:
            xrfdc_utils_out.parent.mkdir(parents=True, exist_ok=True)
            xrfdc_utils_out.write_text(
                render_xrfdc_utils(config, config_path=config_path),
                encoding="utf-8",
            )
    except (OSError, ValueError, yaml.YAMLError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    print(f"Wrote {out}")
    print(f"  config: {config_path}")
    print(f"  project_name: {config.get('project_name', 'cir_sounder')}")
    print(f"  bitstream_name: {config.get('bitstream_name', config.get('project_name', 'cir_sounder'))}")
    if args.run_bitstream:
        print("  run_bitstream: enabled by CLI")
    elif args.no_run_bitstream:
        print("  run_bitstream: disabled by CLI")
    if xrfdc_utils_out is not None:
        print(f"  xrfdc_utils: {xrfdc_utils_out}")
    if args.generate_only:
        print("  vivado: skipped by --generate-only")
        return 0
    return run_vivado(args.vivado, out)


if __name__ == "__main__":
    raise SystemExit(main())
