#!/usr/bin/env python3
"""Compare two timing.json snapshots and report what regressed.

    python3 scripts/timing_diff.py reports/2026-11-20/timing.json reports/2026-11-21/timing.json

Exit code 1 when WNS or TNS got worse, so CI and the nightly job agree on what
'worse' means. The output is written to be pasted straight into an issue.
"""
import json, sys


def load(path):
    with open(path) as fh:
        return json.load(fh)


def best(data):
    runs = [r for r in data.get("runs", []) if r.get("wns") is not None]
    if not runs:
        return None
    return max(runs, key=lambda r: r["wns"])


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    old, new = load(argv[1]), load(argv[2])
    a, b = best(old), best(new)
    if not a or not b:
        print("no graded runs in one of the snapshots")
        return 2

    lines = ["| metric | before | after | delta |", "|---|---|---|---|"]
    regressed = False
    for key in ("wns", "tns"):
        va, vb = a.get(key), b.get(key)
        if va is None or vb is None:
            continue
        d = vb - va
        flag = " **regression**" if (key == "wns" and d < 0) or (key == "tns" and d < 0) else ""
        regressed = regressed or bool(flag)
        lines.append("| %s | %.3f | %.3f | %+.3f%s |" % (key, va, vb, d, flag))
    lines.append("| best seed | %s | %s | |" % (a.get("seed"), b.get("seed")))
    lines.append("| verdict | %s | %s | |" % (old.get("verdict"), new.get("verdict")))

    print("\n".join(lines))
    return 1 if regressed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
