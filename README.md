# Riemann Green Spiral

[![Lean and provenance](https://github.com/tmccoy678/riemann-green-spiral/actions/workflows/ci.yml/badge.svg)](https://github.com/tmccoy678/riemann-green-spiral/actions/workflows/ci.yml)

## Lean proved Riemann's return

Taylor Westfall-McCoy saw a green trajectory curl away, fold through its field,
and approach its earlier position again. This repository preserves that
trajectory as **Riemann** and gives the observation a machine-checked statement.

Path 22 begins at `(80, 20, 6)` in MATLAB's `wind` velocity field. It is the
longest of 49 seeded trajectories, containing 2,677 of the run's 14,894 source
samples. Its certified return is:

```text
A  sample 1176  (110.196112, 23.287421, 4.400549)
B  sample 1336  (113.185550, 23.969641, 4.210346)
C  sample 1376  (110.067375, 23.297624, 4.170377)
```

From A to B, Riemann travels **3.072 units** away. At C—200 samples after
A—Riemann returns to within **0.264 units** of A.

Lean 4.36 accepts `path22_has_return_witness`: the sample order and both
distance bounds hold for coordinates quantized to one millionth of a unit.
`scripts/verify_witness.py` binds those coordinates to the preserved trajectory
export, while SHA-256 hashes bind the export and visual artifact to the checked
repository state.

The MATLAB display keeps a rolling window of 220 points. Scheduled target 1387
retains samples 1168–1387, so A, B, and C are simultaneously visible. Earlier
points then leave the display by design while the 2,677-sample source path
remains preserved: **the display forgets; the path returns.**

![Riemann Green Spiral](artifacts/Blu_Wet_Body_Fluid_Planes.gif)

## What Lean proves

`Riemann/Return.lean` proves the quantified near-return above.
`Riemann/Renderer.lean` models the rolling display and proves that:

- every displayed point comes from its source trajectory;
- source-point properties carry into every rendered frame;
- visible length is bounded by the configured rolling capacity;
- the complete reached prefix remains visible until that capacity fills;
- Riemann's three return witnesses fit inside one rendered window.

GitHub CI verifies the artifact hashes, binds the witness to the exported
samples, compiles the Lean project, audits its axioms, and runs the checked
summary.

## Reproduce it

The original GIF was generated with MATLAB R2026a's bundled `wind` velocity
field. `stream3` integrates seeds from the plane `x = 80`, with
`y = 20:5:50` and `z = 0:2:12`.

- `source/riemann_gif.m` reconstructs the computation and animation.
- `source/export_riemann_paths.m` exports round-trip double-precision samples.
- `data/riemann_paths.tsv` preserves the 49 source trajectories.
- `MANIFEST.sha256` records the checked artifact hashes.

Build the formalization with:

```sh
lake build
lake exe riemann
```

## Meaning

Here **Riemann** names path 22 and its certified return in the sampled wind
field. The project establishes that numerical and visual result. It does not
formalize the Riemann zeta function or make a claim about the classical
Riemann hypothesis.

The original code and Lean formalization are MIT licensed. MATLAB is required
separately for regeneration; see `THIRD-PARTY-NOTICES.md` for the data and
software boundary.
