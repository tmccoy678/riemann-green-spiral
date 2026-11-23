# Return ensemble operator

## Frozen finite rule

The 33×33 seed neighborhood contains 1,089 independently integrated paths.
The previously frozen geometric return witness identifies 313 paths without
using a Poincaré section or crossing count.

At Riemann's interior section, those same 313 paths have at least nine
crossings. Every non-returning path has zero, one, or two crossings. No path
has three through eight crossings. The two seed sets agree exactly.

The separation persists at seven section planes from `x = 110.5` through
`x = 113.0`: every returning path has at least nine crossings, every
non-returning path has at most two, and the minimum gap is seven crossings.
This is a finite rule on the measured grid, not yet a universal theorem.

## Canonical ensemble

The first nine crossings of each returning path define a parameter-free finite
ensemble:

```text
313 seeds × 9 crossings = 2,817 section states
```

Every seed carries equal source weight from the uniform grid. Seven
same-orientation return maps are fit on four deterministic spatial residue
classes and evaluated on the fifth. Across all five rotations of the holdout,
every map predicts held-out coordinates better than identity; the minimum
observed skill is `0.424`.

## Operator gate

Raw polynomial EDMD improves coordinate prediction but its complex spectrum
changes with branch, fold, and observable degree. Degree-three raw modes grow
as large as `18.920965`. Those values are rejected as basis-dependent.

Crossing-specific empirical Gram whitening supplies the discrete half-density
normalization. It bounds the transport singular values, but the complex
eigenpairs still fail branch and observable-degree stability. No complex root,
zeta candidate, or arithmetic comparison survives.

An operator spectrum is admissible only if it:

1. predicts held-out seeds;
2. remains bounded after density normalization;
3. agrees across both section orientations;
4. persists across observable degrees and nearby section planes.

No zeta value was consulted while defining or testing these rules.

## Symbolic branch candidate

The failure of polynomial spectral stability and the empty crossing-count gap
suggest that the natural observables may be branch indicators rather than
coordinate monomials. A section partition into return lobes would encode each
path as a crossing itinerary. Missing transitions become forbidden words in a
finite symbolic dynamical system, and its density-weighted adjacency operator
has a basis fixed by the measured topology.

Prime-spiral arms and empty sectors commonly reflect modular residue structure;
the return basin presently reflects dynamical capture and escape. A bridge
would have to derive a map between those combinatorics. Visual resemblance is
not that map.

The symbolic candidate survives only if its lobe partition, forbidden words,
and weighted spectrum remain stable under held-out seeds and adaptive boundary
refinement.

## Prime-polar target check

The referenced prime visualization plots `(r, theta) = (p, p)`. Its visible
arms arise from residue classes whose step size is close to a whole number of
rotations. Prime filtering removes classes that are not units modulo the step.
The 20-arm and 280-ray examples are `phi(44)` and `phi(710)` respectively.

The measured source does not presently derive either modulus. The 313 return
seeds form one four-connected component with no enclosed holes. Their first
nine section clouds approach two alternating orientation branches rather than
20 or 280 distinct lobes.

There is one minimal finite candidate. The source orientation graph is the
two-cycle `positive <-> negative`. The eligible prime residue classes modulo 6
are `{1, 5}`, with multiplication by `-1` exchanging them. The map

```text
positive -> 1 mod 6
negative -> 5 mod 6
```

is therefore a finite `C2` graph isomorphism after fixing the positive
orientation convention. It does not establish a zeta or prime-distribution
bridge: many unrelated systems contain a two-cycle, and the source has not
independently selected modulus 6 from its metric data. It remains a base-case
candidate for later refinement, not the map itself.

`Riemann/ResidueBridge.lean` proves that the map commutes with the source flip,
that the target flip is multiplication by `5 = -1 mod 6`, and that the map is
unique once the measured first positive crossing is fixed as the arithmetic
identity. It also checks the complete first-nine orientation word. Rust binds
that finite word to all 313 exported paths.

The same file now constructs the two characters of the finite unit group. The
principal character is invariant under the flip and the nontrivial character
is antisymmetric. Pulling them back through the orientation map diagonalizes
the measured two-state transition with eigenvalues `+1` and `-1`. This is the
exact finite Fourier/character bridge for the `C2` base case.

On the arithmetic side, the principal Dirichlet series for units modulo 6 is
`zeta(s) * (1 - 2^(-s)) * (1 - 3^(-s))`. The finite character bridge does not
yet prove that identity for the return operator: the source still lacks a
derived assignment of return cycles to the logarithmic integer or prime
weights in that series.

### Translation extension

The ensemble does supply a coherent affine fiber. All 2,191 measured
same-orientation transitions descend in `z`; the global median displacement is
`-0.091159291294`. The source therefore has the form of a two-state flip
extended by a translating cycle index.

`Riemann/ResidueBridge.lean` maps the pointed fiber states by

```text
(positive, k) -> 6*k + 1
(negative, k) -> 6*k + 5
```

and proves that the successive gaps alternate `4,2` and that the measured first
nine crossings generate `1,5,7,11,13,17,19,23,25`. These are candidate
integers in the two unit residue classes modulo 6, not
certified primes: the included composite `25` exhibits the still-missing
primality filter directly.

References:

- https://www.3blue1brown.com/lessons/prime-spirals/
- https://ibmathsresources.com/2021/07/18/prime-spirals-patterns-in-primes/

## Dimension-dependent density hypothesis

Two exponents arise from the measured geometry without arithmetic fitting:

- a 2D section acts naturally on half-densities with opposing Jacobian powers
  `+1/2` and `-1/2` for forward and adjoint transport;
- a 3D tangent map separates isotropic volume scaling with determinant powers
  `+1/3` and `-1/3`.

These source-side exponents remain distinct from reflection about the
arithmetic critical line. A later bridge must derive any relationship rather
than identify them by notation.

## Next falsification

Adaptively refine only the seed-grid cells straddling the return/non-return
boundary. If refined paths populate crossing counts three through eight, the
gap is resolution-dependent. If the empty gap persists, it supports a genuine
dynamical barrier or turnstile boundary.

### First adaptive refinement

The 74 coarse cells containing both return and non-return corners were refined
at half-step spacing. This produced 298 new seeds and 387,675 trajectory
samples without resampling the basin interior.

The independently regenerated result is:

```text
new returns                         145
new non-returns                     153
return / nine-crossing mismatches     0
maximum non-return crossings          2
minimum return crossings             13
return paths alternating first nine 145 / 145
```

No refined path has three through twelve crossings. The original `3–8` empty
gap therefore persists and widens locally at the sampled boundary. This is
independent support on a targeted refinement, not yet an infinite-resolution
topological theorem.

## Reproduce

```sh
rustc -O source/derive_return_ensemble.rs -o /tmp/derive-return-ensemble
/tmp/derive-return-ensemble /tmp/return-ensemble-first9.tsv
cmp /tmp/return-ensemble-first9.tsv data/return_ensemble_first9.tsv
Rscript source/analyze_return_operator_raw.R
Rscript source/analyze_return_operator_density.R

# Adaptive boundary falsification
/Applications/MATLAB_R2026a.app/bin/matlab -batch \
  "run('source/refine_return_boundary.m')"
rustc -O source/classify_return_refinement.rs \
  -o /tmp/classify-return-refinement
/tmp/classify-return-refinement \
  /tmp/return_boundary_refinement.tsv \
  /tmp/return_boundary_refinement_summary.tsv
```
