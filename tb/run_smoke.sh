#!/usr/bin/env bash
# Run the smoke test with whatever simulator is installed.
#   ./tb/run_smoke.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if command -v iverilog >/dev/null 2>&1; then
    iverilog -g2012 -o /tmp/tb_smoke tb/tb_smoke.sv tb/stub_dut.sv
    vvp /tmp/tb_smoke
elif command -v verilator >/dev/null 2>&1; then
    verilator --binary --timing -Wno-fatal -o /tmp/tb_smoke_verilator tb/tb_smoke.sv tb/stub_dut.sv
    /tmp/tb_smoke_verilator
else
    echo "no simulator found: install iverilog or verilator" >&2
    exit 127
fi
