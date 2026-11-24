# Result: the incoming Path 22 geometry is wave-like from the side

The ordered view begins at the backward-traced measured field edge, passes
through the original `(80,20,6)` seed, and ends at the previously declared
central-channel entry at forward sample 1176.

## Geometry

| Quantity | Value |
|---|---:|
| Ordered points | 1,211 |
| Three-dimensional arc length | 189.9252 |
| Endpoint chord | 36.2936 |
| Arc/chord ratio | 5.2330 |
| Vertical residual turning points | 20 |
| Transverse residual turning points | 34 |

The side view resolves two components:

- `z(s)` supplies a slowly descending envelope with smaller smooth reversals;
- transverse displacement supplies a broad incoming lobe, counter-turn,
  overshoot, and increasingly rapid oscillations into the recurrent channel.

The largest spectral component is one broad cycle. The shorter later
oscillations form a nonstationary, chirped capture sequence rather than a
single constant-frequency sinusoid.

The measured intake is therefore geometrically described as

`broad incoming wave -> counter-turn -> chirped capture -> recurrence`.

This is an ordered spatial streamline in a frozen steady field. Establishing a
physical propagating wave would require a measured time coordinate; the
wave-like side geometry itself is directly present in the committed path.

The `paper/` directory contains a two-column publication figure in vector PDF,
SVG, and 600-dpi PNG formats, together with the formal coordinate definition
and manuscript caption.

## Reproduction

```sh
matlab -batch \
  "addpath('explorations/entry_wave'); export_entry_wave"
python3 explorations/entry_wave/analyze_entry_wave.py
```

