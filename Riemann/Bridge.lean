import Riemann.Nulls
import Lean.Elab.Tactic.Grind

namespace Riemann

/-- Squared numerator norm after writing `2s = twiceRe + i*twiceIm`. -/
def cayleyNumeratorNormSq (twiceRe twiceIm : Int) : Int :=
  twiceRe ^ 2 + twiceIm ^ 2

/-- Squared denominator norm for the transform `s / (1 - s)`. -/
def cayleyDenominatorNormSq (twiceRe twiceIm : Int) : Int :=
  (2 - twiceRe) ^ 2 + twiceIm ^ 2

/-- Equal Cayley numerator and denominator norms select the critical line. -/
theorem cayley_unit_circle_iff_critical_line (twiceRe twiceIm : Int) :
    cayleyNumeratorNormSq twiceRe twiceIm =
        cayleyDenominatorNormSq twiceRe twiceIm ↔
      twiceRe = 1 := by
  unfold cayleyNumeratorNormSq cayleyDenominatorNormSq
  grind

/-- Channel characteristic coefficients, quantized at 10⁻⁹. -/
def channelTraceNano : Int := 2_992_930_725
def channelSecondCoefficientNano : Int := 2_992_856_527
def channelDeterminantNano : Int := 999_920_547

/-- The measured channel polynomial is close to reciprocal form. -/
def channelNearReciprocalCertificate : Prop :=
  channelTraceNano - channelSecondCoefficientNano = 74_198 ∧
  1_000_000_000 - channelDeterminantNano = 79_453 ∧
  channelTraceNano - channelSecondCoefficientNano < 100_000 ∧
  1_000_000_000 - channelDeterminantNano < 100_000

theorem channel_operator_is_near_reciprocal :
    channelNearReciprocalCertificate := by
  unfold channelNearReciprocalCertificate channelTraceNano
    channelSecondCoefficientNano channelDeterminantNano
  decide

end Riemann
