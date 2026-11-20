# tb/

AXI testbench. Needs the DUT, not the board — which is the whole reason it can
run in parallel with bring-up instead of queueing behind it.

| file | owns |
|---|---|
| `axi_master_bfm.sv` | drives read/write bursts, supports up to N outstanding |
| `scoreboard.sv` | expected vs actual, per-ID accounting |
| `regression.list` | what runs on every push |

The BFM is deliberately parameterised on outstanding depth: single-outstanding is
the functional baseline, multi-outstanding is what the bandwidth numbers need.
