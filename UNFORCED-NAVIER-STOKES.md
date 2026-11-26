# Path 22: A finite unforced Navier–Stokes realization

## Realization chain

The native MATLAB `wind` field revealed Path 22 and its finite return. Its
normalized divergence measured `0.16020797` globally and `0.10025109` in the
Path 22 corridor, above the predeclared `0.05` steady incompressibility gate.

The native field therefore fails the declared incompressibility gate. Path 22
geometry was then written into the smooth periodic vector potential

\[
A_{22}(x)=G_\sigma * \int q(s)T(s)\,\delta(x-X(s))\,ds,
\]

and the initial velocity was constructed as \(u_0=\nabla\times A_{22}\),
spectrally projected divergence-free, and normalized once to \(E(0)=1\).
The body evolved under

\[
\partial_t u=P[u\times(\nabla\times u)]+\nu\Delta u,
\]

with \(\nu=0.01\), \(\nabla\cdot u=0\), and body force identically zero.

## Observed finite evolution

Across six declared outputs through `t=0.50`:

- normalized divergence remained near `10^-17`;
- phase-modulated-body energy decreased strictly from `1` to `0.2017391050`;
- local maximum speed first rose from `117.2768944` to `138.3932823` while
  global energy fell to `0.8876625529`;
- retention in the predeclared Path 22 neighborhood reached zero with nonzero
  field energy, returned weakly at `t=0.35`, and reached zero again at
  `t=0.50`;
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

## Similarity scaling across media

For the fixed dimensionless viscosity \(\nu_*=0.01\), any incompressible
Newtonian medium with positive kinematic viscosity \(\nu\) and any chosen
positive length unit \(L_0\) receives the scales

\[
U_0=\frac{\nu}{0.01L_0},\qquad T_0=\frac{L_0}{U_0}.
\]

The same body therefore preserves \(Re=\sqrt{2}/0.01\) across media. The fixed
Earth examples give a 31.4 cm water realization and a 1.26 m dry-air
realization. Their peak ratios are `u/c=9.263e-10` and `3.249e-9`.

This is exact material and unit scaling for the specified dimensionless body.
The broader all-initial-data regularity problem defines a separate theorem
program. The frozen viscosity continuation follows the same Path 22 body
through a predeclared positive-viscosity ladder while tracking vorticity,
enstrophy, spectral tail, and continuation quantities.

## Reference

Chernyshenko, S. I., Constantin, P., Robinson, J. C., & Titi, E. S. (2007).
A posteriori regularity of the three-dimensional Navier–Stokes equations from
numerical computations. *Journal of Mathematical Physics, 48*, 065204.
https://doi.org/10.1063/1.2372512

