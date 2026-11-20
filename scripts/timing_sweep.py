#!/usr/bin/env python3
"""Run place & route across N seeds and record what each one did.

The point is not to find a lucky seed. It is to tell apart a routing accident
from a structural problem: if the same path fails in most seeds, no amount of
re-running will save it.

Usage:
    python3 scripts/timing_sweep.py --seeds 8 [--dry-run]

Output: reports/<date>/timing.json
    {
      "design": "...", "commit": "...", "at": "...",
      "runs": [{"seed": 1, "wns": -0.412, "tns": -8.31, "failing": 7,
                "wall_s": 2418, "log": "reports/2026-11-21/seed1.log"}],
      "verdict": "structural" | "routing"
    }

Verdict rule (kept deliberately simple):
    failing_seeds / total_seeds >= 0.5  -> structural
    otherwise                           -> routing, re-run before touching RTL
"""
import argparse, datetime as dt, json, os, subprocess, sys

REPORTS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "reports")


def commit():
    try:
        return subprocess.run(["git", "rev-parse", "--short", "HEAD"],
                              capture_output=True, text=True, check=True).stdout.strip()
    except Exception:
        return "unknown"


def run_seed(seed, outdir, dry_run):
    log = os.path.join(outdir, "seed%d.log" % seed)
    cmd = ["efx_run", "--flow", "compile", "--seed", str(seed)]
    if dry_run:
        return {"seed": seed, "wns": None, "tns": None, "failing": None,
                "wall_s": None, "log": log, "skipped": True}
    started = dt.datetime.now()
    with open(log, "w") as fh:
        subprocess.run(cmd, stdout=fh, stderr=subprocess.STDOUT)
    wall = (dt.datetime.now() - started).total_seconds()
    return dict(parse_report(log), seed=seed, wall_s=round(wall, 1), log=log)


def parse_report(log):
    """Pull WNS/TNS/failing-path count out of an Efinity timing report.

    Kept in one place on purpose: the report format is the part most likely to
    change between tool versions, and this is the only function that has to.
    """
    wns = tns = failing = None
    try:
        with open(log, errors="replace") as fh:
            for line in fh:
                low = line.lower()
                if "worst negative slack" in low and ":" in line:
                    wns = float(line.split(":")[-1].split()[0])
                elif "total negative slack" in low and ":" in line:
                    tns = float(line.split(":")[-1].split()[0])
                elif "failing paths" in low and ":" in line:
                    failing = int(line.split(":")[-1].split()[0])
    except OSError:
        pass
    return {"wns": wns, "tns": tns, "failing": failing}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seeds", type=int, default=8)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    day = dt.date.today().isoformat()
    outdir = os.path.join(REPORTS, day)
    os.makedirs(outdir, exist_ok=True)

    runs = [run_seed(s, outdir, args.dry_run) for s in range(1, args.seeds + 1)]
    graded = [r for r in runs if not r.get("skipped") and r.get("wns") is not None]
    bad = [r for r in graded if r["wns"] < 0]
    verdict = "unknown"
    if graded:
        verdict = "structural" if len(bad) / len(graded) >= 0.5 else "routing"

    result = {"design": "ti180-lpddr4", "commit": commit(),
              "at": dt.datetime.now().isoformat(timespec="seconds"),
              "runs": runs, "verdict": verdict}
    path = os.path.join(outdir, "timing.json")
    with open(path, "w") as fh:
        json.dump(result, fh, indent=2)
    print(json.dumps({k: result[k] for k in ("commit", "verdict")}, indent=2))
    print("wrote", path)
    return 0 if not bad else 1


if __name__ == "__main__":
    sys.exit(main())
