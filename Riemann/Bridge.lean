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

section OperatorBridge

variable {K V W : Type} [SMul K V] [SMul K W]

/-- An eigen-relation without assuming any particular linear-algebra library. -/
def IsEigenRelation (operator : V → V) (value : K) (vector : V) : Prop :=
  operator vector = value • vector

/-- A map that respects scalar action and intertwines two operators. -/
structure OperatorIntertwiner (source : V → V) (target : W → W) where
  map : V → W
  map_smul : ∀ (value : K) (vector : V), map (value • vector) = value • map vector
  operator_commutes : ∀ vector : V, map (source vector) = target (map vector)

/-- Any genuine intertwiner carries a source eigen-relation to the target. -/
theorem OperatorIntertwiner.carries_eigen_relation
    {source : V → V} {target : W → W}
    (bridge : OperatorIntertwiner (K := K) source target)
    {value : K} {vector : V}
    (relation : IsEigenRelation (K := K) source value vector) :
    IsEigenRelation (K := K) target value (bridge.map vector) := by
  unfold IsEigenRelation at relation ⊢
  rw [← bridge.operator_commutes, relation, bridge.map_smul]

end OperatorBridge

end Riemann
