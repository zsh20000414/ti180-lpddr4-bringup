# Build log

Public log: <https://blog.zhangshuhao.top/build-log/ti180/>

## Entry format

Each entry records the same fields so the numbers stay comparable:

```text
build   date + commit + seed
loop    place & route wall time, programming time, training time
timing  WNS, TNS, number of failing paths
train   pass/fail per rank, plus the failing stage (write leveling, read gate, VREF)
board   error counters after N minutes of traffic
what    the one change that went in
```

## 2026-11-20 — scaffolding

Repo created. No board runs yet. The loop being instrumented:

1. `efx_run` place & route, wall time recorded per seed
2. bitstream archived with commit + seed
3. programming and training time recorded separately from P&R
4. counter read after a fixed traffic pattern, so runs are comparable

First real entry lands once the toolchain runs unattended on the build machine.
