# Riemann Green Spiral

This directory preserves and begins formalizing the MATLAB visualization Taylor
and Blu named **Riemann** on 2026-11-20.

> **Scope:** this is a Lean-checked visualization and provenance artifact. It
> does not claim a proof of the Riemann hypothesis or a new physical law.

## Literal object

The original GIF was generated from MATLAB R2026a's bundled `wind` velocity
field. `stream3` integrated 49 seeded trajectories from the plane `x = 80`,
with `y = 20:5:50` and `z = 0:2:12`. The run contains 14,894 source samples;
individual paths range from 10 to 2,677 samples. The renderer progressively
reveals those paths over 84 scheduled targets and holds the final image for 12
additional frames.

The green returning trajectory is path 22, seeded at `(80, 20, 6)`. It is the
longest trajectory in the run at 2,677 samples. Between samples 1176 and 1376,
it travels at least 3.0 coordinate units away from its earlier point and returns
within 0.3 units of it. `Riemann/Return.lean` checks a conservative quantized
witness for that return, and `scripts/verify_witness.py` binds the witness to
the preserved TSV export.

`source/riemann_gif.m` is a portable reconstruction of the exact computation,
rendering parameters, and animation schedule used to create the original GIF.
Only its output location was changed from an absolute Desktop path to the
repository's `artifacts/` directory. `source/export_riemann_paths.m` exports
the numerical trajectories at round-trip double precision into
`data/riemann_paths.tsv`.

## First Lean boundary

`Riemann/Renderer.lean` proves a property of the visual evidence pipeline:

- each displayed trajectory is a prefix of a MATLAB-produced source path;
- a displayed point must already exist in that source path;
- every property established for all source points is inherited by every frame;
- a frame at or beyond the path length displays the complete path.
- path 22 contains the stated 200-sample return witness.

This certifies the renderer's structural honesty. It does not assert that the
MATLAB `wind` dataset is a physical measurement, that `stream3` is formally
verified, or that the green trajectory proves the Riemann hypothesis.

The MIT license covers the original source and Lean formalization in this
repository. The preserved MATLAB-derived artifact and trajectory export remain
subject to any applicable MathWorks terms and are included privately for
provenance pending a redistribution review.

See `THIRD-PARTY-NOTICES.md` for the MATLAB dependency and data boundary.

## Build

```sh
lake build
lake exe riemann
```
