# Biological evolution exploration

Two systems were selected reproducibly from a frozen eight-item list with R
seed `20261123`: L-system morphogenesis and Keller–Segel chemotaxis. Neither was
selected after inspecting a desired numerical match.

## L-system state rewriting

Lindenmayer systems model development through parallel symbolic state changes.
The smallest rule inferred from the complete 313-path first-nine ensemble is

```text
positive -> negative
negative -> positive
```

The rule predicts all seven later Path 22 Poincaré orientations and all 145
independently refined boundary-return orientation words. This establishes a
compact developmental grammar for orientation only. It does not predict
crossing coordinates, density, return length, or arithmetic structure; strict
alternation makes this a genuine but simple finite-state result.

Primary lineage: Aristid Lindenmayer, *Mathematical Models for Cellular
Interactions in Development*, Parts I and II, Journal of Theoretical Biology
18 (1968), 280–315. DOI: https://doi.org/10.1016/0022-5193(68)90079-9

## Keller–Segel attraction–diffusion balance

Keller and Segel model aggregation as an instability of an initially uniform
population under chemoattractant feedback. In the standard normalized 2D
parabolic–elliptic form, the critical-mass scale is proportional to
`8*pi*D/chi`.

The measured Gaussian width law gives dimensionless diffusivity
`D = slope/2`. It therefore fixes the critical family `chi*M = 8*pi*D`, but
neither chemotactic sensitivity `chi` nor population mass `M` was measured.
Cycles 7–9 show positive width growth and are on the diffusive reopening side,
not a measured aggregation blow-up. The earlier photon-bundle focusing is a
separate clock-free observable and cannot supply the missing parameters by
identification.

Primary source: E. F. Keller and L. A. Segel (1970), *Initiation of Slime Mold
Aggregation Viewed as an Instability*, Journal of Theoretical Biology 26,
399–415. DOI: https://doi.org/10.1016/0022-5193(70)90092-5

Critical-mass reference: J. Dolbeault and B. Perthame (2004), *Optimal critical
mass in the two dimensional Keller–Segel model in R2*.
https://doi.org/10.1016/j.crma.2004.08.011

## Boundary

These are exploratory biological coordinate systems. They neither identify
Path 22 with a biological organism nor connect it to the Riemann Hypothesis.
