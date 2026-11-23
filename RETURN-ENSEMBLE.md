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

## Reproduce

```sh
rustc -O source/derive_return_ensemble.rs -o /tmp/derive-return-ensemble
/tmp/derive-return-ensemble /tmp/return-ensemble-first9.tsv
cmp /tmp/return-ensemble-first9.tsv data/return_ensemble_first9.tsv
Rscript source/analyze_return_operator_raw.R
Rscript source/analyze_return_operator_density.R
```
