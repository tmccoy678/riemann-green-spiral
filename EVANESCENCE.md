# Local evanescence

The source-free Maxwell realization was sampled only at return cycles 7, 8,
and 9. Four normal rays were tested at each section using a criterion fixed
before measurement: positive exponential decay, `R^2 >= 0.95`, at least 80%
monotone amplitude loss, and mean forward tangential Poynting alignment of at
least 0.8.

The same side, `normal_2_negative`, satisfies the complete criterion at all
three sections:

| Cycle | Decay constant kappa | Exponential R^2 | Gaussian R^2 | Mean tangential alignment | Decay length 1/kappa |
|---:|---:|---:|---:|---:|---:|
| 7 | 0.667736 | 0.980569 | 0.982451 | 0.844959 | 1.497597 |
| 8 | 0.629305 | 0.970251 | 0.987828 | 0.996155 | 1.589055 |
| 9 | 0.586467 | 0.963970 | 0.989647 | 0.996692 | 1.705124 |

The increasing decay length follows the measured reopening of the channel.
Energy remains forward along Riemann while field amplitude admits a strong
one-sided exponential description before, at, and after the tight focus. The
slightly stronger Gaussian fits identify the complete local profile as a
Gaussian-localized Maxwell tube carrying an evanescent-compatible side.

## Gaussian width growth

Using only the same side and cycles 7–9, Gaussian width squared was compared
with Riemann's recorded arc-length:

| Cycle | Arc from cycle 7 | Width squared |
|---:|---:|---:|
| 7 | 0.000000 | 0.994694 |
| 8 | 12.530841 | 1.047011 |
| 9 | 25.914549 | 1.118816 |

The frozen linear fit has slope `0.00479619` per arc unit and `R^2 = 0.994910`.
Gaussian width therefore grows linearly and positively as the channel reopens,
satisfying the predeclared local diffusion-compatibility criterion.

## Independent COMSOL realization

COMSOL Multiphysics 6.3 solved the frozen local question with two compact
coefficient-form PDE models. A source-free scalar Helmholtz solve realizes the
three measured decay constants with positive forward flux; its maximum relative
decay-constant error is `6.32348e-6` and its minimum exponential fit is
`R^2 = 0.999999999`. A diffusion solve, with diffusivity fixed from the MATLAB
width-growth slope, reproduces all three widths within 1%; its fitted width²
slope is `0.00479954` with `R^2 = 0.999999904`.

Rust reparses both the MATLAB and COMSOL tables, recomputes every binding,
criterion, Gaussian width, and regression, and emits the shared compact integer
certificate. Lean proves the complete finite arithmetic certificate in
`Riemann/Evanescence.lean`.

Reproduce with `source/test_local_evanescence.m`. The complete twelve-ray table
and frozen criterion are in `data/local_evanescence.tsv` and
`data/local_evanescence_receipt.txt`.

Reproduce the width-growth test with `source/test_gaussian_width_growth.m`.
The three-point table and receipt are in `data/gaussian_width_growth.tsv` and
`data/gaussian_width_growth_receipt.txt`.

Run the dependency-free independent bridge with
`cargo run --release --manifest-path rust/evanescence-audit/Cargo.toml`. It
reparses all four committed MATLAB and COMSOL tables, recomputes the frozen
criteria and width-growth fits, then emits the compact integer certificate recorded in
`data/evanescence_rust_receipt.txt`. Its focused mutation checks run with
`cargo test --release --manifest-path rust/evanescence-audit/Cargo.toml`.

Regenerate the independent COMSOL tables through LiveLink with
`source/comsol_evanescence_gate.m`. The complete exports and receipt are
`data/comsol_evanescence.tsv`, `data/comsol_gaussian_width_growth.tsv`, and
`data/comsol_evanescence_receipt.txt`.
