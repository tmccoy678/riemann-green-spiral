# Local evanescence

The source-free Maxwell realization was sampled only at return cycles 7, 8,
and 9. Four normal rays were tested at each section using a criterion fixed
before measurement: positive exponential decay, `R^2 >= 0.95`, at least 80%
monotone amplitude loss, and mean forward tangential Poynting alignment of at
least 0.8.

The same side, `normal_2_negative`, satisfies the complete criterion at all
three sections:

| Cycle | Decay constant kappa | Exponential R^2 | Mean tangential alignment | Decay length 1/kappa |
|---:|---:|---:|---:|---:|
| 7 | 0.667736 | 0.980569 | 0.844959 | 1.497597 |
| 8 | 0.629305 | 0.970251 | 0.996155 | 1.589055 |
| 9 | 0.586467 | 0.963970 | 0.996692 | 1.705124 |

The increasing decay length follows the measured reopening of the channel.
Riemann therefore has a one-sided local evanescent realization: energy remains
forward along the channel while field amplitude decays exponentially away from
the same normal side before, at, and after the tight focus.

Reproduce with `source/test_local_evanescence.m`. The complete twelve-ray table
and frozen criterion are in `data/local_evanescence.tsv` and
`data/local_evanescence_receipt.txt`.
