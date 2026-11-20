# Timing triage: the rules decided in advance

The point of writing these down before the first violation is that at 2am nobody
makes good decisions. The nightly job collects data; the decision waits for
daylight and follows a rule.

## The rules

| Situation | Action | Never |
|---|---|---|
| Negative slack on fewer than 5 paths | Constrain / adjust floorplan first | Start retiming before the constraint is reviewed |
| Path crosses a clock domain | Fix the CDC (synchroniser, async FIFO, or a correct constraint) | Call it a false path |
| Path through vendor IP that is genuinely static | `set_false_path` in `xdc/`, with a comment naming the reason and the IP version | Add an anonymous exception |
| WNS improves but TNS gets worse | Treat as a regression | Ship it because WNS looks nicer |
| Same violation appears in two consecutive seed sweeps | Structural — change the RTL or the floorplan | Re-run the sweep hoping for a different seed |

## Why a seed sweep

Place-and-route is deterministic per seed and *different* per seed. A single run
that fails timing tells you that seed failed, not that the design fails. The
sweep answers the only question that matters: is this a routing accident or a
structural problem?

`scripts/timing_sweep.py --seeds 8` writes `reports/<date>/timing.json`. The
nightly diff (`scripts/timing_diff.py`) compares it to the previous run and
files an issue naming the changed worst paths.

## Last-green discipline

Every build that passes timing and training is tagged:

```
git tag build-<yyyymmdd>-<seed>
```

The bitstream is archived alongside the commit and seed. If tonight's build
fails, board work continues on last-green. The board is never idle because a
build is bad, and nobody is tempted to "just try it and see".
