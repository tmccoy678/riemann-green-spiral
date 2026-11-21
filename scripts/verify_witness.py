#!/usr/bin/env python3
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    (22, 1176): (110196112, 23287421, 4400549),
    (22, 1336): (113185550, 23969641, 4210346),
    (22, 1376): (110067375, 23297624, 4170377),
}

observed = {}
with (ROOT / "data" / "riemann_paths.tsv").open(newline="") as handle:
    for row in csv.DictReader(handle, delimiter="\t"):
        key = (int(row["path_id"]), int(row["point_id"]))
        if key in EXPECTED:
            observed[key] = tuple(
                round(float(row[axis]) * 1_000_000) for axis in ("x", "y", "z")
            )

if observed != EXPECTED:
    raise SystemExit(f"witness mismatch: {observed!r}")

before = observed[(22, 1176)]
far = observed[(22, 1336)]
after = observed[(22, 1376)]

def squared_distance(a, b):
    return sum((left - right) ** 2 for left, right in zip(a, b))

assert squared_distance(before, far) >= 9_000_000_000_000
assert squared_distance(before, after) <= 90_000_000_000
print("PATH22_WITNESS_VERIFIED")
