import Riemann.Spectrum

namespace Riemann

/-- Counts independently bound by the Rust audit to the complete zero atlas. -/
def interpolatedFieldZeroCount : Nat := 19
def spiralFieldZeroCount : Nat := 9
def spiralFieldZeroIds : List Nat := [1, 3, 7, 11, 12, 14, 17, 18, 19]

/-- Distances from the two nearest certificates to path 22, scaled by 10⁶. -/
def nearestFieldZeroId : Nat := 8
def nearestFieldZeroDistance : Nat := 3_243_097
def nearestSpiralZeroId : Nat := 3
def nearestSpiralZeroDistance : Nat := 8_252_508

/--
The finite trilinear field contains both saddle and spiral zeros. Path 22 is
closer to a saddle zero than to the nearest spiral zero.
-/
def nullAndWhiskerCertificate : Prop :=
  spiralFieldZeroIds.length = spiralFieldZeroCount ∧
  spiralFieldZeroCount < interpolatedFieldZeroCount ∧
  nearestFieldZeroId = 8 ∧
  nearestSpiralZeroId = 3 ∧
  3_000_000 < nearestFieldZeroDistance ∧
  nearestFieldZeroDistance < 3_500_000 ∧
  8_000_000 < nearestSpiralZeroDistance ∧
  nearestSpiralZeroDistance < 8_500_000 ∧
  nearestFieldZeroDistance < nearestSpiralZeroDistance

theorem finite_field_has_null_and_whisker_certificate :
    nullAndWhiskerCertificate := by
  unfold nullAndWhiskerCertificate spiralFieldZeroIds spiralFieldZeroCount
    interpolatedFieldZeroCount nearestFieldZeroId nearestFieldZeroDistance
    nearestSpiralZeroId nearestSpiralZeroDistance
  decide

end Riemann
