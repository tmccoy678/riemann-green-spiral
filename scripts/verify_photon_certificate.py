#!/usr/bin/env python3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def receipt(name: str) -> dict[str, str]:
    lines = (ROOT / "data" / name).read_text(encoding="utf-8").splitlines()
    return dict(line.split("=", 1) for line in lines if "=" in line)


def scaled(value: str, factor: float) -> int:
    return round(float(value) * factor)


bundle = receipt("photon_neighbor_bundle_receipt.txt")
maxwell = receipt("source_free_maxwell_receipt.txt")
controls = receipt("maxwell_controls_receipt.txt")

observed = {
    "crossing_cycles": int(bundle["positive_crossing_cycles"]),
    "caustic_folds": int(bundle["orientation_flips"]),
    "focus_micro": scaled(bundle["maximum_flux_density_multiplier"], 1e6),
    "local_residual_atto": scaled(bundle["maximum_local_maxwell_residual"], 1e18),
    "gauss_e_atto": scaled(maxwell["gauss_electric_t1"], 1e18),
    "gauss_b_atto": scaled(maxwell["gauss_magnetic_t1"], 1e18),
    "energy_atto": scaled(maxwell["energy_relative_residual"], 1e18),
    "alignment_0_nano": scaled(maxwell["poynting_weighted_alignment_t0"], 1e9),
    "alignment_1_nano": scaled(maxwell["poynting_weighted_alignment_t1"], 1e9),
    "forward_nano": scaled(maxwell["poynting_positive_fraction_t1"], 1e9),
    "alignment_24_nano": scaled(controls["riemann_full_grid_24_alignment_t1"], 1e9),
    "alignment_32_nano": scaled(controls["riemann_full_grid_32_alignment_t1"], 1e9),
    "alignment_40_nano": scaled(controls["riemann_full_grid_40_alignment_t1"], 1e9),
}

expected = {
    "crossing_cycles": 14,
    "caustic_folds": 3,
    "focus_micro": 57_653_220,
    "local_residual_atto": 14_274,
    "gauss_e_atto": 101,
    "gauss_b_atto": 99,
    "energy_atto": 3_821,
    "alignment_0_nano": 998_659_640,
    "alignment_1_nano": 918_292_502,
    "forward_nano": 1_000_000_000,
    "alignment_24_nano": 919_642_465,
    "alignment_32_nano": 918_574_933,
    "alignment_40_nano": 918_292_502,
}

if observed != expected:
    raise SystemExit(f"PHOTON_CERTIFICATE_FAILED: {observed!r}")

print("PHOTON_CERTIFICATE_VERIFIED")
