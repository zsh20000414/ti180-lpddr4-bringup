# rtl/

Wrapper around the vendor LPDDR4 controller plus the AXI shim that the testbench
and the host driver both talk to.

| file | owns |
|---|---|
| `lpddr4_wrap.sv` | controller instantiation, clock/reset, calibration status |
| `axi_shim.sv` | AXI4 slave -> controller native interface, ID mapping |
| `regs.sv` | the register map that `docs/memory-map.md` documents |

Rule: one change at a time, and every change gets a build log entry with the
timing delta it caused.
