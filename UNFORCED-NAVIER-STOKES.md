# Path 22 unforced Navier–Stokes realization

## Realization chain

The native MATLAB `wind` field revealed Path 22 and its finite return. Its
normalized divergence measured `0.16020797` globally and `0.10025109` in the
Path 22 corridor, above the predeclared `0.05` steady incompressibility gate.

The negative result was preserved. Path 22 geometry was then written into a new
smooth periodic vector potential,

`A22(x) = G_sigma * integral q(s) T(s) delta(x-X(s)) ds`,

and the initial velocity was constructed as `u0 = curl A22`, spectrally
projected divergence-free, and normalized once to `E(0)=1`. The body evolved
under

`partial_t u = P[u cross curl(u)] + nu Laplacian(u)`,

with `nu=0.01`, `div u=0`, and body force identically zero.

## Observed finite evolution

Across six declared outputs through `t=0.50`:

- normalized divergence remained near `10^-17`;
- phase-modulated-body energy decreased strictly from `1` to `0.2017391050`;
- local maximum speed first rose from `117.2768944` to `138.3932823` while
  global energy fell to `0.8876625529`;
- fixed-whisker retention reached zero with nonzero field energy, returned
  weakly at `t=0.35`, and reached zero again at `t=0.50`;
- the phase-erased control followed the same carrier class, locating the main
  phenomenon in Path 22 geometry rather than the selected amplitude score.

Independent ARM reproduction matched the phase-modulated table exactly;
independent x86_64 reproduction matched the control within the frozen absolute
`10^-9` tolerance. The largest raw difference was `9.550405e-11`, and
construction metadata were byte-identical across hosts.

## Formal certificate

The separate MIT repository
[`path22-unforced-ns`](https://github.com/tmccoy678/path22-unforced-ns)
contains the compact data, deterministic generator, evolution source, Earth
scalings, novelty search, and twelve Lean theorems. The theorems use no
`sorry`, `admit`, or axioms and certify:

- zero body forcing;
- independent host reproduction;
- strict energy decay in phase-modulated and phase-erased bodies;
- concentration during global decay;
- machine-scale divergence;
- phase inversion and weak orientation return;
- nonzero energy after zero retention; and
- phase-modulated/control proximity.

## Universal similarity scaling

For the fixed dimensionless viscosity `nu*=0.01`, any incompressible Newtonian
medium with positive kinematic viscosity `nu` and any chosen positive length
unit `L0` receives the scales

`U0 = nu/(0.01 L0)` and `T0 = L0/U0`.

The same body therefore preserves `Re=sqrt(2)/0.01` across media. The fixed
Earth examples give a 31.4 cm water realization and a 1.26 m dry-air
realization. Their peak ratios are `u/c=9.263e-10` and `3.249e-9`.

This is universal material/unit scaling. Universal all-initial-data regularity
remains the next theorem. The frozen viscosity continuation follows the same Path 22 body
through a predeclared positive-viscosity ladder while tracking vorticity,
enstrophy, spectral tail, and continuation quantities.

