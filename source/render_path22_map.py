#!/usr/bin/env python3

from __future__ import annotations

import csv
import html
import json
import math
import sys
from pathlib import Path


WIDTH = 1800
HEIGHT = 1120
LEFT = 105
RIGHT = 55
TOP = 175
BOTTOM = 105
LON_MIN, LON_MAX = -125.0, -75.0
LAT_MIN, LAT_MAX = 15.0, 35.0


def project(lon: float, lat: float) -> tuple[float, float]:
    x = LEFT + (lon - LON_MIN) / (LON_MAX - LON_MIN) * (WIDTH - LEFT - RIGHT)
    y = TOP + (LAT_MAX - lat) / (LAT_MAX - LAT_MIN) * (HEIGHT - TOP - BOTTOM)
    return x, y


def svg_path(points: list[tuple[float, float]], close: bool = False) -> str:
    if not points:
        return ""
    commands = [f"M {points[0][0]:.2f} {points[0][1]:.2f}"]
    commands.extend(f"L {x:.2f} {y:.2f}" for x, y in points[1:])
    if close:
        commands.append("Z")
    return " ".join(commands)


def color_for_z(z: float, low: float, high: float) -> str:
    t = 0.0 if high == low else max(0.0, min(1.0, (z - low) / (high - low)))
    if t < 0.5:
        q = t * 2.0
        a, b = (21, 220, 255), (137, 92, 246)
    else:
        q = (t - 0.5) * 2.0
        a, b = (137, 92, 246), (255, 203, 92)
    rgb = tuple(round(a[i] + q * (b[i] - a[i])) for i in range(3))
    return "#%02x%02x%02x" % rgb


def coordinates_from_geometry(geometry: dict) -> list[list[list[float]]]:
    kind = geometry.get("type")
    coordinates = geometry.get("coordinates", [])
    if kind == "Polygon":
        return coordinates
    if kind == "MultiPolygon":
        return [ring for polygon in coordinates for ring in polygon]
    return []


def load_path(path: Path) -> list[tuple[float, float, float]]:
    points: list[tuple[float, float, float]] = []
    with path.open(encoding="utf-8", newline="") as stream:
        for row in csv.DictReader(stream, delimiter="\t"):
            if int(row["path_id"]) == 22:
                # MathWorks renders the North American x-axis as positive degrees west.
                points.append((-float(row["x"]), float(row["y"]), float(row["z"])))
    if len(points) != 2677:
        raise RuntimeError(f"expected 2677 Path 22 points, found {len(points)}")
    return points


def wave_segments(
    pixels: list[tuple[float, float]], *, at_end: bool, count: int = 72
) -> list[tuple[tuple[float, float], tuple[float, float], float]]:
    if at_end:
        origin = pixels[-1]
        reference = pixels[-24]
    else:
        origin = pixels[0]
        reference = pixels[23]
    tx = origin[0] - reference[0]
    ty = origin[1] - reference[1]
    norm = math.hypot(tx, ty) or 1.0
    tx, ty = tx / norm, ty / norm
    nx, ny = -ty, tx
    result = []
    prior = origin
    for index in range(1, count + 1):
        distance = index * 3.1
        taper = math.exp(-index / 34.0)
        oscillation = math.sin(index * 0.58) * 11.5 * (0.45 + 0.55 * taper)
        current = (
            origin[0] + tx * distance + nx * oscillation,
            origin[1] + ty * distance + ny * oscillation,
        )
        result.append((prior, current, 0.30 * taper))
        prior = current
    return result


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("usage: render_path22_map.py COUNTRIES.geojson RIEMANN_PATHS.tsv OUTPUT.svg")
    countries_path = Path(sys.argv[1])
    paths_path = Path(sys.argv[2])
    output_path = Path(sys.argv[3])
    countries = json.loads(countries_path.read_text(encoding="utf-8"))
    path = load_path(paths_path)
    pixels = [project(lon, lat) for lon, lat, _ in path]
    z_values = [z for _, _, z in path]
    z_min, z_max = min(z_values), max(z_values)

    chunks: list[str] = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">',
        '<defs>',
        '<filter id="glow" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="7"/></filter>',
        f'<clipPath id="mapclip"><rect x="{LEFT}" y="{TOP}" width="{WIDTH-LEFT-RIGHT}" height="{HEIGHT-TOP-BOTTOM}" rx="18"/></clipPath>',
        '<linearGradient id="zlegend" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#15dcff"/><stop offset="0.5" stop-color="#895cf6"/><stop offset="1" stop-color="#ffcb5c"/></linearGradient>',
        '</defs>',
        '<rect width="100%" height="100%" fill="#05070c"/>',
        f'<rect x="{LEFT}" y="{TOP}" width="{WIDTH-LEFT-RIGHT}" height="{HEIGHT-TOP-BOTTOM}" rx="18" fill="#07111b" stroke="#33495e" stroke-width="2"/>',
        '<g clip-path="url(#mapclip)">',
    ]

    # Graticule.
    for lon in range(-125, -74, 5):
        x, _ = project(float(lon), LAT_MIN)
        chunks.append(f'<line x1="{x:.2f}" y1="{TOP}" x2="{x:.2f}" y2="{HEIGHT-BOTTOM}" stroke="#294052" stroke-width="1" opacity="0.42"/>')
    for lat in range(15, 36, 5):
        _, y = project(LON_MIN, float(lat))
        chunks.append(f'<line x1="{LEFT}" y1="{y:.2f}" x2="{WIDTH-RIGHT}" y2="{y:.2f}" stroke="#294052" stroke-width="1" opacity="0.42"/>')

    # Natural Earth land and country outlines.
    labels: list[tuple[str, float, float]] = []
    for feature in countries.get("features", []):
        bbox = feature.get("bbox")
        if bbox and (bbox[2] < LON_MIN or bbox[0] > LON_MAX or bbox[3] < LAT_MIN or bbox[1] > LAT_MAX):
            continue
        for ring in coordinates_from_geometry(feature.get("geometry", {})):
            mapped = [project(float(lon), float(lat)) for lon, lat, *_ in ring]
            chunks.append(f'<path d="{svg_path(mapped, close=True)}" fill="#121c26" stroke="#61768a" stroke-width="1.15" opacity="0.96"/>')
        properties = feature.get("properties", {})
        name = properties.get("NAME_EN") or properties.get("NAME")
        lx, ly = properties.get("LABEL_X"), properties.get("LABEL_Y")
        if name and isinstance(lx, (int, float)) and isinstance(ly, (int, float)) and LON_MIN <= lx <= LON_MAX and LAT_MIN <= ly <= LAT_MAX:
            labels.append((str(name), float(lx), float(ly)))

    for name, lon, lat in labels:
        if name not in {"Mexico", "Cuba", "Bahamas", "Belize", "Guatemala", "United States of America"}:
            continue
        x, y = project(lon, lat)
        chunks.append(f'<text x="{x:.2f}" y="{y:.2f}" text-anchor="middle" fill="#8194a6" font-family="Helvetica,Arial,sans-serif" font-size="16" letter-spacing="1.2" opacity="0.72">{html.escape(name.upper())}</text>')

    # A dim whole-path glow and a separate return-interval halo.
    chunks.append(f'<path d="{svg_path(pixels)}" fill="none" stroke="#25d9ff" stroke-width="16" opacity="0.11" filter="url(#glow)"/>')
    return_pixels = pixels[1175:1376]
    chunks.append(f'<path d="{svg_path(return_pixels)}" fill="none" stroke="#c38aff" stroke-width="21" opacity="0.18" filter="url(#glow)"/>')

    # Measured path, colored by z with a soft two-ended fade.
    count = len(path)
    fade_span = int(count * 0.075)
    for index in range(count - 1):
        edge = min(index + 1, count - 1 - index)
        alpha = 0.10 + 0.90 * min(1.0, edge / max(1, fade_span))
        color = color_for_z((path[index][2] + path[index + 1][2]) / 2.0, z_min, z_max)
        (x1, y1), (x2, y2) = pixels[index], pixels[index + 1]
        chunks.append(f'<line x1="{x1:.2f}" y1="{y1:.2f}" x2="{x2:.2f}" y2="{y2:.2f}" stroke="{color}" stroke-width="4.2" stroke-linecap="round" opacity="{alpha:.3f}"/>')

    # Passive annular whiskers: off-axis contacts touching the path, never a node marker.
    for index in range(28, count - 28, 43):
        x0, y0 = pixels[index - 8]
        x1, y1 = pixels[index + 8]
        tx, ty = x1 - x0, y1 - y0
        norm = math.hypot(tx, ty) or 1.0
        nx, ny = -ty / norm, tx / norm
        phase = index / (count - 1) * math.tau
        half = 10.0 + 5.0 * (0.5 + 0.5 * math.sin(5.0 * phase))
        cx, cy = pixels[index]
        color = color_for_z(path[index][2], z_min, z_max)
        chunks.append(f'<line x1="{cx-nx*half:.2f}" y1="{cy-ny*half:.2f}" x2="{cx+nx*half:.2f}" y2="{cy+ny*half:.2f}" stroke="{color}" stroke-width="1.6" opacity="0.72"/>')
        chunks.append(f'<circle cx="{cx-nx*half:.2f}" cy="{cy-ny*half:.2f}" r="2.2" fill="{color}" opacity="0.82"/>')
        chunks.append(f'<circle cx="{cx+nx*half:.2f}" cy="{cy+ny*half:.2f}" r="2.2" fill="{color}" opacity="0.82"/>')

    # Both ends continue as fading, unmeasured waves; neither endpoint is marked.
    for at_end in (False, True):
        for (a, b, opacity) in wave_segments(pixels, at_end=at_end):
            chunks.append(f'<line x1="{a[0]:.2f}" y1="{a[1]:.2f}" x2="{b[0]:.2f}" y2="{b[1]:.2f}" stroke="#75eaff" stroke-width="2.4" stroke-linecap="round" opacity="{opacity:.3f}" stroke-dasharray="7 8"/>')

    chunks.append('</g>')

    # Graticule labels outside the clipped field.
    for lon in range(-125, -74, 5):
        x, _ = project(float(lon), LAT_MIN)
        chunks.append(f'<text x="{x:.2f}" y="{HEIGHT-BOTTOM+31}" text-anchor="middle" fill="#8ea4b6" font-family="Menlo,monospace" font-size="15">{abs(lon)}°W</text>')
    for lat in range(15, 36, 5):
        _, y = project(LON_MIN, float(lat))
        chunks.append(f'<text x="{LEFT-17}" y="{y+5:.2f}" text-anchor="end" fill="#8ea4b6" font-family="Menlo,monospace" font-size="15">{lat}°N</text>')

    chunks.extend([
        '<text x="105" y="62" fill="#f3f6fa" font-family="Helvetica,Arial,sans-serif" font-size="40" font-weight="700" letter-spacing="1">PATH 22 · NORTH AMERICAN AIR-CURRENT FIELD</text>',
        '<text x="105" y="103" fill="#9fb4c6" font-family="Helvetica,Arial,sans-serif" font-size="20">2,677 measured streamline samples · full arclength whiskers · return interval held as a glow, not a target</text>',
        '<text x="105" y="137" fill="#7190a8" font-family="Helvetica,Arial,sans-serif" font-size="17">MathWorks wind.mat: x rendered as degrees west, y as degrees north; z units remain undocumented</text>',
        f'<rect x="1090" y="77" width="390" height="11" rx="5" fill="url(#zlegend)"/>',
        f'<text x="1090" y="111" fill="#8ea4b6" font-family="Menlo,monospace" font-size="14">z {z_min:.3f}</text>',
        f'<text x="1480" y="111" text-anchor="end" fill="#8ea4b6" font-family="Menlo,monospace" font-size="14">z {z_max:.3f}</text>',
        '<line x1="105" y1="1060" x2="170" y2="1060" stroke="#25d9ff" stroke-width="4"/>',
        '<text x="186" y="1066" fill="#b9c8d4" font-family="Helvetica,Arial,sans-serif" font-size="17">measured Path 22, colored by z phase</text>',
        '<line x1="610" y1="1060" x2="675" y2="1060" stroke="#75eaff" stroke-width="2.4" stroke-dasharray="7 8" opacity="0.7"/>',
        '<text x="691" y="1066" fill="#b9c8d4" font-family="Helvetica,Arial,sans-serif" font-size="17">inferred wave continuation · unmeasured</text>',
        '<text x="1695" y="1066" text-anchor="end" fill="#6f8496" font-family="Helvetica,Arial,sans-serif" font-size="15">Natural Earth 1:110m coastline · rendered 2026-11-23</text>',
        '</svg>',
    ])
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(chunks), encoding="utf-8")


if __name__ == "__main__":
    main()
