# ti180-lpddr4-bringup

Bring-up of the LPDDR4 controller on an Efinix Titanium TI180 dev kit, with the
AXI testbench and CI that makes the bring-up loop repeatable instead of heroic.

**Status: scaffolding.** The first milestone is a reproducible single-channel
LPDDR4 bring-up with published numbers: place-and-route wall time, WNS/TNS per
build, training result per build, and board error counters per run.

## Why this repo exists

FPGA bring-up is not hard because the thinking is hard. It is hard because the
loop is serial and slow:

```
RTL change -> place & route (35-60 min) -> bitstream -> program -> train -> read counters
```

One board, one power cycle at a time. Anything that does not need the board
should not be waiting behind that loop. This repo splits the work so that:

* `rtl/` + `xdc/` own the bring-up loop (one change at a time, measured),
* `tb/` owns the AXI testbench and the regression queue (no hardware needed),
* `scripts/` owns the nightly tooling: seed sweeps, timing diffs, report writing,
* `docs/` owns the build log and the decision rules used when things break.

## Layout

```
rtl/            LPDDR4 controller wrapper, AXI shim, clock/reset
tb/             AXI master BFM, scoreboard, regression list
xdc/            constraints: clocks, IO, false paths (every exception commented)
scripts/        timing_sweep.py, timing_diff.py, report.py
docs/           build-log.md, timing-triage.md, memory-map.md
.github/        CI: lint + sim on push; P&R on a self-hosted runner, nightly
```

## Non-negotiables

1. **Vendor SDK is not vendored.** Referenced by version and checksum. This repo
   stays publishable while the vendor tree stays where it belongs.
2. **Unverified builds are never flashed.** Sign-off on a bitstream is a human
   step, on purpose.
3. **Every timing exception carries a written reason.** No anonymous false paths.
4. **Numbers get published.** Build time, slack, training result, error counters.
   If it is not measured, it did not happen.

## Build log

Weekly, at <https://blog.zhangshuhao.top/build-log/ti180/>:

* what changed, what the loop cost in wall-clock minutes,
* WNS/TNS before and after,
* which runs passed training and what the counters looked like,
* what the parallel sessions did while the board was busy.

## License

Code in this repository is MIT. The vendor SDK it references is not redistributed
here and remains under its own license.
