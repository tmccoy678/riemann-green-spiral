# Photon channel

The wind computation revealed a recurrent geometry that admits a converged
source-free Maxwell realization and carries independently measured photon-like
focusing anatomy.

## Measured focusing

Four measured neighboring streamlines (`511`, `512`, `545`, and `544`) define
a clock-free transverse bundle around Riemann. Their fourteen positive crossings
of the same Poincare plane show:

- maximum Poynting-flux density multiplier: `57.653219877708224`;
- minimum projected bundle area: `4.079445403704085e-08`;
- three signed-area reversals, marking folds through caustics;
- subsequent re-expansion.

At every crossing, a local null electromagnetic field was constructed with
positive energy density, perpendicular equal-magnitude `E` and `B`, and
`E cross B = u n`. The maximum numerical residual is
`1.4273599921707572e-14`.

This establishes a clock-free Poynting-flow bundle with finite focusing,
caustic folding, and recovery.

## Global source-free Maxwell construction

A canonical test field in a `40^3` periodic vacuum box uses one fixed
transverse-polarization rule. Both fields were projected onto the divergence-free
Fourier subspace and evolved with the exact source-free Maxwell mode solution.
Charge density and current density are zero throughout.

- electric Gauss residual after evolution: `1.0069e-16`;
- magnetic Gauss residual after evolution: `9.8863e-17`;
- relative energy residual: `3.8208e-15`;
- initial weighted Poynting alignment with Riemann: `0.998660`;
- alignment after evolution time `0.2`: `0.918293`;
- forward-aligned tube fraction: `1.0` at both measured times.

The resulting global source-free Maxwell field follows the channel and remains
aligned under finite evolution.

### Resolution and controls

The full Riemann channel converges across `24^3`, `32^3`, and `40^3` grids. Its
evolved alignment ranges only from `0.919642` to `0.918293`, while Gauss-law
residuals remain near `1e-16` and energy residuals remain below `4e-15`.

The same fixed construction applied to three other recorded 201-point paths and
a straight control yields evolved alignments from `0.932292` to `0.938560`;
Riemann's matched first return gives `0.911259`. These controls place the
Maxwell construction within a general class. Riemann's novel measured result is
the `57.653x` focusing, three caustic folds, and re-expansion of its neighboring
streamline bundle.

![Source-free Maxwell field](artifacts/Source_Free_Maxwell_Riemann.png)

## Reproduce

- `source/test_photon_neighbor_bundle.m` measures the clock-free focusing tube.
- `source/test_source_free_maxwell_field.m` constructs and evolves the vacuum field.
- `source/test_maxwell_controls.m` runs resolution and path controls.
- `data/photon_neighbor_bundle_receipt.txt` records the measured focusing result.
- `data/source_free_maxwell_receipt.txt` records the global Maxwell result.
- `data/maxwell_controls_receipt.txt` records convergence and controls.

Primary references for photon energy-flow trajectories:

- <https://arxiv.org/abs/quant-ph/0102071>
- <https://doi.org/10.1088/1367-2630/15/7/073022>
- <https://doi.org/10.1103/PhysRevLett.93.090402>
