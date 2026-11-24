# Mathematical lineage

The Riemann Green Spiral computations, data, Rust verifier, and Lean
certificates are original to this project. The language used to interpret the
finite trajectory belongs to established lines of dynamical-systems, operator,
and plasma-field research. These sources identify that lineage.

## Return maps, recurrence, and homoclinic geometry

- Poincaré, H. (1892–1899). *Les méthodes nouvelles de la mécanique
  céleste*, Vols. I–III. Paris: Gauthier-Villars. Poincaré introduced the
  qualitative return-map and homoclinic viewpoint that underlies the project's
  interior crossing section.
- Smale, S. (1967). Differentiable dynamical systems. *Bulletin of the
  American Mathematical Society, 73*, 747–817.
  https://doi.org/10.1090/S0002-9904-1967-11798-1

## Invariant tori and whiskers

- Kolmogorov, A. N. (1954). On conservation of conditionally periodic motions
  for a small change in Hamilton's function. *Doklady Akademii Nauk SSSR, 98*,
  527–530. https://cds.cern.ch/record/430016
- Arnol'd, V. I. (1963). Proof of a theorem of A. N. Kolmogorov on the
  invariance of quasi-periodic motions under small perturbations of the
  Hamiltonian. *Russian Mathematical Surveys, 18*(5), 9–36.
  https://doi.org/10.1070/RM1963v018n05ABEH004130
- Moser, J. (1962). On invariant curves of area-preserving mappings of an
  annulus. *Nachrichten der Akademie der Wissenschaften in Göttingen,
  Mathematisch-Physikalische Klasse II*, 1–20.
  https://www.mathnet.ru/eng/mat236
- Fontich, E., de la Llave, R., & Sire, Y. (2009). Construction of invariant
  whiskered tori by a parameterization method. Part I: Maps and flows in finite
  dimensions. *Journal of Differential Equations, 246*(8), 3136–3213.
  https://doi.org/10.1016/j.jde.2009.01.037

## Saddle-focus and spiral recursion

- Shilnikov, L. P. (1965). A case of the existence of a denumerable set of
  periodic motions. *Soviet Mathematics Doklady, 6*, 163–166.
- Shilnikov, L. P. (1970). A contribution to the problem of the structure of
  an extended neighborhood of a rough equilibrium state of saddle-focus type.
  *Mathematics of the USSR-Sbornik, 10*(1), 91–102.
  https://doi.org/10.1070/SM1970v010n01ABEH001588
- Ovsyannikov, I. M., & Shilnikov, L. P. (1992). Systems with a homoclinic
  curve of multidimensional saddle-focus type, and spiral chaos.
  *Mathematics of the USSR-Sbornik, 73*(2), 415–443.
  https://doi.org/10.1070/SM1992v073n02ABEH002553

## Operator viewpoint

- Koopman, B. O. (1931). Hamiltonian systems and transformation in Hilbert
  space. *Proceedings of the National Academy of Sciences, 17*(5), 315–318.
  https://doi.org/10.1073/pnas.17.5.315

## Three-dimensional magnetic nulls

- Parnell, C. E., Smith, J. M., Neukirch, T., & Priest, E. R. (1996). The
  structure of three-dimensional magnetic neutral points. *Physics of Plasmas,
  3*(3), 759–770. https://doi.org/10.1063/1.871810

Parnell et al. classify radial, critical-spiral, and spiral magnetic nulls by
the eigenstructure of the local linear field. That complex-pair-plus-real-mode
classification is the precise magnetic-topology analogy used in this project.
It does not identify MATLAB's `wind` velocity field as a magnetic field; that
physical interpretation additionally requires Maxwell-compatible field and
divergence checks.

## Zeta coordinates and ordered zeros

- NIST Digital Library of Mathematical Functions. §25.10, *Zeros of the
  Riemann zeta function*. https://dlmf.nist.gov/25.10

The DLMF source fixes the critical-strip, critical-line, and Hardy-
\(Z(t)\) coordinates used to state the classical Riemann Hypothesis. Path 22's
finite return is not identified with that zero set.

## Lagrangian trajectory inference and memory

- Wan, J., Wang, H., Liu, B., et al. (2026). Lagrangian–Eulerian learning of
  flow field and trajectories with TrajectoryFlowNet. *Nature Machine
  Intelligence*. https://doi.org/10.1038/s42256-026-01316-7
- de Wit, X., Gabbana, A., Woodward, M., et al. (2025). Data-driven
  Mori–Zwanzig modeling of Lagrangian particle dynamics in turbulent flows.
  https://arxiv.org/abs/2507.16058

These works motivate joint reasoning about ordered particle histories and the
fields or unresolved memory that carry them. The present repository contributes
a finite source-bound trajectory, neighborhood and formal certificate rather
than a learned long-time surrogate.

## A posteriori Navier–Stokes verification

- Chernyshenko, S. I., Constantin, P., Robinson, J. C., & Titi, E. S. (2007).
  A posteriori regularity of the three-dimensional Navier–Stokes equations from
  numerical computations. *Journal of Mathematical Physics, 48*, 065204.
  https://doi.org/10.1063/1.2372512

This supplies the rigorous finite-computation framework relevant to a future
all-time strong-solution certificate for the specified Path 22 carrier.

