# Third-party notices

This project requires a separately licensed MATLAB installation to regenerate
the numerical trajectories and GIF.

The scripts use MATLAB's documented `load wind` and `stream3` example. The
MathWorks-supplied `wind.mat` input dataset, MATLAB source code, binaries, and
toolboxes are not included in this repository. The TSV and GIF are generated
outputs from the documented example with independently chosen seed density,
visual design, animation schedule, audit boundary, and formalization.

`data/path22_flow.tsv` is a derived interpolation of that omitted field at the
already-preserved path-22 coordinates. `data/path22_neighborhood_0125.tsv` is a
derived 33×33 seed exploration. Rust and Lean verify the committed outputs and
their internal certificates, while exact regeneration of those two derived
files still requires a separately licensed MATLAB installation and its bundled
`wind` dataset.

MATLAB and MathWorks are trademarks of The MathWorks, Inc. Their mention does
not imply endorsement. Users are responsible for operating MATLAB under their
own applicable license.

The repository's MIT license applies to Taylor Westfall-McCoy's original code
and Lean formalization; it does not relicense MATLAB or the omitted `wind.mat`
input dataset.
