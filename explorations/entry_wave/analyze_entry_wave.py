#!/usr/bin/env python3
"""Render and quantify the ordered side view of Path 22's incoming segment."""

from __future__ import annotations

import cmath
import csv
import math
from pathlib import Path


HERE = Path(__file__).resolve().parent
INPUT = HERE / "output" / "path22_entry.tsv"
OUT = HERE / "output"
SMOOTH_WINDOW = 21
RESAMPLE_N = 1024


def read_rows() -> list[dict[str, float | str]]:
    with INPUT.open(newline="") as handle:
        rows = []
        for row in csv.DictReader(handle, delimiter="\t"):
            rows.append(
                {
                    "point_id": int(row["point_id"]),
                    "source": row["source"],
                    "x": float(row["x"]),
                    "y": float(row["y"]),
                    "z": float(row["z"]),
                }
            )
        return rows


def cumulative_arc(rows: list[dict[str, float | str]]) -> list[float]:
    result = [0.0]
    for a, b in zip(rows, rows[1:]):
        result.append(
            result[-1]
            + math.sqrt(
                (float(b["x"]) - float(a["x"])) ** 2
                + (float(b["y"]) - float(a["y"])) ** 2
                + (float(b["z"]) - float(a["z"])) ** 2
            )
        )
    return result


def linear_fit(x: list[float], y: list[float]) -> tuple[float, float]:
    xb, yb = sum(x) / len(x), sum(y) / len(y)
    slope = sum((a - xb) * (b - yb) for a, b in zip(x, y)) / sum((a - xb) ** 2 for a in x)
    return yb - slope * xb, slope


def moving_average(values: list[float], window: int) -> list[float]:
    half = window // 2
    prefix = [0.0]
    for value in values:
        prefix.append(prefix[-1] + value)
    result = []
    for i in range(len(values)):
        lo, hi = max(0, i - half), min(len(values), i + half + 1)
        result.append((prefix[hi] - prefix[lo]) / (hi - lo))
    return result


def turning_points(values: list[float], min_separation: int = 20) -> list[int]:
    smooth = moving_average(values, SMOOTH_WINDOW)
    candidates = []
    prior = 0
    for i in range(1, len(smooth) - 1):
        left, right = smooth[i] - smooth[i - 1], smooth[i + 1] - smooth[i]
        sign = 1 if right > 0 else -1 if right < 0 else prior
        if prior and sign and sign != prior:
            candidates.append(i)
        if sign:
            prior = sign
    selected: list[int] = []
    for index in candidates:
        if not selected or index - selected[-1] >= min_separation:
            selected.append(index)
        elif abs(values[index]) > abs(values[selected[-1]]):
            selected[-1] = index
    return selected


def interpolate(x: list[float], y: list[float], target: float) -> float:
    lo, hi = 0, len(x) - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if x[mid] <= target:
            lo = mid
        else:
            hi = mid
    if x[hi] == x[lo]:
        return y[lo]
    q = (target - x[lo]) / (x[hi] - x[lo])
    return y[lo] + q * (y[hi] - y[lo])


def dominant_cycles(s: list[float], residual: list[float]) -> tuple[int, float]:
    grid = [s[-1] * i / (RESAMPLE_N - 1) for i in range(RESAMPLE_N)]
    values = [interpolate(s, residual, target) for target in grid]
    mean = sum(values) / len(values)
    values = [value - mean for value in values]
    energies = []
    total = sum(value * value for value in values) or 1.0
    for k in range(1, 65):
        coefficient = sum(
            value * cmath.exp(-2j * math.pi * k * n / RESAMPLE_N)
            for n, value in enumerate(values)
        )
        energies.append((abs(coefficient) ** 2, k))
    energy, cycles = max(energies)
    return cycles, energy / (RESAMPLE_N * total)


def scale_points(x: list[float], y: list[float], box: tuple[float, float, float, float]) -> list[tuple[float, float]]:
    left, top, width, height = box
    xmin, xmax, ymin, ymax = min(x), max(x), min(y), max(y)
    padx = (xmax - xmin) * 0.04 or 1.0
    pady = (ymax - ymin) * 0.08 or 1.0
    xmin, xmax = xmin - padx, xmax + padx
    ymin, ymax = ymin - pady, ymax + pady
    return [
        (
            left + (a - xmin) / (xmax - xmin) * width,
            top + height - (b - ymin) / (ymax - ymin) * height,
        )
        for a, b in zip(x, y)
    ]


def path_d(points: list[tuple[float, float]]) -> str:
    return "M" + " L".join(f"{x:.2f},{y:.2f}" for x, y in points)


def color(q: float) -> str:
    a, b = (28, 221, 238), (255, 172, 64)
    rgb = tuple(round(x + q * (y - x)) for x, y in zip(a, b))
    return "#%02x%02x%02x" % rgb


def colored_curve(points: list[tuple[float, float]]) -> list[str]:
    chunks = []
    for i, (a, b) in enumerate(zip(points, points[1:])):
        q = (i + 0.5) / (len(points) - 1)
        chunks.append(
            f'<path d="M{a[0]:.2f},{a[1]:.2f} L{b[0]:.2f},{b[1]:.2f}" stroke="{color(q)}" stroke-width="2.7" fill="none" stroke-linecap="round"/>'
        )
    return chunks


def main() -> None:
    rows = read_rows()
    s = cumulative_arc(rows)
    x = [float(row["x"]) for row in rows]
    y = [float(row["y"]) for row in rows]
    z = [float(row["z"]) for row in rows]
    seed_i = next(i for i, row in enumerate(rows) if row["source"] == "seed")

    dx, dy = x[-1] - x[0], y[-1] - y[0]
    norm = math.hypot(dx, dy)
    ex, ey = dx / norm, dy / norm
    nx, ny = -ey, ex
    transverse = [(xx - x[0]) * nx + (yy - y[0]) * ny for xx, yy in zip(x, y)]

    z_a, z_b = linear_fit(s, z)
    t_a, t_b = linear_fit(s, transverse)
    z_trend = [z_a + z_b * value for value in s]
    t_trend = [t_a + t_b * value for value in s]
    z_resid = [value - trend for value, trend in zip(z, z_trend)]
    t_resid = [value - trend for value, trend in zip(transverse, t_trend)]
    z_turns = turning_points(z_resid)
    t_turns = turning_points(t_resid)
    z_cycles, z_fraction = dominant_cycles(s, z_resid)
    t_cycles, t_fraction = dominant_cycles(s, t_resid)
    chord_3d = math.sqrt((x[-1]-x[0])**2 + (y[-1]-y[0])**2 + (z[-1]-z[0])**2)

    out_rows = []
    for i, row in enumerate(rows):
        out_rows.append(
            {
                "point_id": i + 1,
                "source": row["source"],
                "arc": f"{s[i]:.12f}",
                "x": f"{x[i]:.12f}",
                "y": f"{y[i]:.12f}",
                "z": f"{z[i]:.12f}",
                "transverse": f"{transverse[i]:.12f}",
                "z_linear_residual": f"{z_resid[i]:.12f}",
                "transverse_linear_residual": f"{t_resid[i]:.12f}",
            }
        )
    with (OUT / "entry_side_coordinates.tsv").open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(out_rows[0]), delimiter="\t")
        writer.writeheader()
        writer.writerows(out_rows)

    panels = {
        "top": (100.0, 205.0, 480.0, 560.0),
        "vertical": (660.0, 205.0, 480.0, 560.0),
        "transverse": (1220.0, 205.0, 480.0, 560.0),
    }
    top_points = scale_points(x, y, panels["top"])
    vertical_points = scale_points(s, z, panels["vertical"])
    vertical_trend = scale_points(s, z_trend, panels["vertical"])
    transverse_points = scale_points(s, transverse, panels["transverse"])
    transverse_trend = scale_points(s, t_trend, panels["transverse"])

    chunks = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="1800" height="1000" viewBox="0 0 1800 1000">',
        '<rect width="100%" height="100%" fill="#071018"/>',
        '<text x="900" y="58" text-anchor="middle" fill="#edf6ff" font-family="Times New Roman,serif" font-size="35" font-weight="bold">Path 22 before the spiral</text>',
        '<text x="900" y="96" text-anchor="middle" fill="#91a9bb" font-family="Menlo,monospace" font-size="16">measured field edge → original seed → declared channel entry · color follows order</text>',
    ]
    for title, key in [
        ("Top view · x,y", "top"),
        ("Side elevation · order,z", "vertical"),
        ("Side profile · order,transverse", "transverse"),
    ]:
        left, top, width, height = panels[key]
        chunks.append(f'<rect x="{left-35}" y="145" width="{width+70}" height="675" rx="18" fill="#0b1822" stroke="#244153"/>')
        chunks.append(f'<text x="{left+width/2}" y="184" text-anchor="middle" fill="#dcebf5" font-family="Times New Roman,serif" font-size="23">{title}</text>')
    chunks.extend(colored_curve(top_points))
    chunks.append(f'<path d="{path_d(vertical_trend)}" stroke="#506879" stroke-width="1.5" stroke-dasharray="8 8" fill="none"/>')
    chunks.extend(colored_curve(vertical_points))
    chunks.append(f'<path d="{path_d(transverse_trend)}" stroke="#506879" stroke-width="1.5" stroke-dasharray="8 8" fill="none"/>')
    chunks.extend(colored_curve(transverse_points))

    for points in (top_points, vertical_points, transverse_points):
        for index, label, fill in [(0, "edge", "#1cdded"), (seed_i, "seed", "#9be4c3"), (len(rows)-1, "channel", "#ffac40")]:
            px, py = points[index]
            chunks.append(f'<circle cx="{px:.2f}" cy="{py:.2f}" r="6" fill="{fill}" stroke="#071018" stroke-width="2"/>')
            chunks.append(f'<text x="{px+9:.2f}" y="{py-9:.2f}" fill="{fill}" font-family="Menlo,monospace" font-size="13">{label}</text>')

    for index in z_turns:
        px, py = vertical_points[index]
        chunks.append(f'<circle cx="{px:.2f}" cy="{py:.2f}" r="3.2" fill="#ffed95"/>')
    for index in t_turns:
        px, py = transverse_points[index]
        chunks.append(f'<circle cx="{px:.2f}" cy="{py:.2f}" r="3.2" fill="#ffed95"/>')

    chunks.extend(
        [
            f'<text x="900" y="872" text-anchor="middle" fill="#ffce73" font-family="Menlo,monospace" font-size="23">arc/chord = {s[-1]/chord_3d:.3f} · vertical turns = {len(z_turns)} · transverse turns = {len(t_turns)}</text>',
            f'<text x="900" y="913" text-anchor="middle" fill="#c5d7e3" font-family="Menlo,monospace" font-size="16">detrended dominant cycles: z {z_cycles} ({z_fraction:.1%} band energy) · transverse {t_cycles} ({t_fraction:.1%} band energy)</text>',
            '<text x="900" y="958" text-anchor="middle" fill="#607d8f" font-family="Times New Roman,serif" font-size="16">Yellow points are side-profile turning points after the frozen 21-sample smoothing window.</text>',
            '</svg>',
        ]
    )
    (OUT / "entry_wave_side_view.svg").write_text("\n".join(chunks))

    receipt = f"""PATH 22 ENTRY-WAVE GEOMETRY
date=2026-11-24
entry_points={len(rows)}
edge_x={x[0]:.15g}
edge_y={y[0]:.15g}
edge_z={z[0]:.15g}
seed_point_index={seed_i+1}
channel_entry_forward_sample=1176
entry_arc_length={s[-1]:.15g}
entry_endpoint_chord={chord_3d:.15g}
arc_to_chord_ratio={s[-1]/chord_3d:.15g}
vertical_residual_turns={len(z_turns)}
transverse_residual_turns={len(t_turns)}
vertical_dominant_cycles={z_cycles}
vertical_dominant_band_energy_fraction={z_fraction:.15g}
transverse_dominant_cycles={t_cycles}
transverse_dominant_band_energy_fraction={t_fraction:.15g}
smoothing_window_samples={SMOOTH_WINDOW}

The side profiles describe ordered streamline geometry in a frozen steady field.
They do not assign a physical time or identify a propagating particle wave.
"""
    (OUT / "receipt.txt").write_text(receipt)
    print(receipt)


if __name__ == "__main__":
    main()

