import Riemann.ResidueBridge

namespace Riemann

/-- The six admissible residue positions in one complete mod-18 candidate bar. -/
inductive UnitModEighteen where
  | one
  | five
  | seven
  | eleven
  | thirteen
  | seventeen
  deriving DecidableEq, Repr

def UnitModEighteen.value : UnitModEighteen → Nat
  | .one => 1
  | .five => 5
  | .seven => 7
  | .eleven => 11
  | .thirteen => 13
  | .seventeen => 17

/-- Advance once through the cyclic `4,2,4,2,4,2` boundary bar. -/
def UnitModEighteen.next : UnitModEighteen → UnitModEighteen
  | .one => .five
  | .five => .seven
  | .seven => .eleven
  | .eleven => .thirteen
  | .thirteen => .seventeen
  | .seventeen => .one

def UnitModEighteen.gap : UnitModEighteen → Nat
  | .one => 4
  | .five => 2
  | .seven => 4
  | .eleven => 2
  | .thirteen => 4
  | .seventeen => 2

theorem UnitModEighteen.advance_by_gap (residue : UnitModEighteen) :
    (residue.value + residue.gap) % 18 = residue.next.value := by
  cases residue <;> decide

/-- Additive negation modulo 18 supplies three intrinsic opposite pairs. -/
def UnitModEighteen.negate : UnitModEighteen → UnitModEighteen
  | .one => .seventeen
  | .five => .thirteen
  | .seven => .eleven
  | .eleven => .seven
  | .thirteen => .five
  | .seventeen => .one

theorem UnitModEighteen.negate_is_multiply_by_seventeen
    (residue : UnitModEighteen) :
    (17 * residue.value) % 18 = residue.negate.value := by
  cases residue <;> decide

/-- Three signed current coordinates, one for each negation pair. -/
def UnitModEighteen.currents : UnitModEighteen → Int × Int × Int
  | .one => (1, 0, 0)
  | .seventeen => (-1, 0, 0)
  | .five => (0, 1, 0)
  | .thirteen => (0, -1, 0)
  | .seven => (0, 0, 1)
  | .eleven => (0, 0, -1)

theorem UnitModEighteen.negate_reverses_currents
    (residue : UnitModEighteen) :
    residue.negate.currents =
      (-residue.currents.1,
       -residue.currents.2.1,
       -residue.currents.2.2) := by
  cases residue <;> rfl

def modEighteenBoundary : List Nat := [1, 5, 7, 11, 13, 17]

theorem mod_eighteen_boundary_values_are_exact :
    [UnitModEighteen.one, .five, .seven, .eleven, .thirteen, .seventeen].map
        UnitModEighteen.value = modEighteenBoundary := by
  rfl

/-- The six gaps close one full bar: the last `+2` reaches `19 = 1 mod 18`. -/
theorem mod_eighteen_boundary_gaps_are_4_2_4_2_4_2 :
    ([1, 5, 7, 11, 13, 17, 19].zip [5, 7, 11, 13, 17, 19]).map
      (fun pair => pair.2 - pair.1) = [4, 2, 4, 2, 4, 2] := by
  decide

theorem mod_eighteen_boundary_closes : 19 % 18 = 1 := by
  decide

/-- Exhaustive finite certificate for the unit residue classes modulo 18. -/
theorem units_mod_eighteen_are_exact :
    (List.range 18).filter (fun residue => decide (Nat.Coprime residue 18)) =
      modEighteenBoundary := by
  decide

theorem UnitModEighteen.is_coprime (residue : UnitModEighteen) :
    Nat.Coprime residue.value 18 := by
  cases residue <;> decide

/-- Coprimality with 6 and with 18 selects exactly the same integers. -/
theorem coprime_six_iff_coprime_eighteen (n : Nat) :
    Nat.Coprime n 6 ↔ Nat.Coprime n 18 := by
  constructor
  · intro h6
    have h6' : Nat.Coprime n (2 * 3) := by simpa using h6
    have h3 : Nat.Coprime n 3 := (Nat.coprime_mul_iff_right.mp h6').2
    have h18' : Nat.Coprime n (6 * 3) :=
      Nat.coprime_mul_iff_right.mpr ⟨h6, h3⟩
    simpa using h18'
  · intro h18
    have h18' : Nat.Coprime n (6 * 3) := by simpa using h18
    exact (Nat.coprime_mul_iff_right.mp h18').1

/-- The first complete six-crossing candidate bar is the mod-18 boundary. -/
def firstSixFiberStates : List ReturnFiberState := firstNineFiberStates.take 6

theorem first_six_crossings_form_the_mod_eighteen_boundary :
    firstSixFiberStates.map
      (fun state => state.candidateNumber % 18) = modEighteenBoundary := by
  decide

/-- The seventh crossing begins the same boundary bar again. -/
theorem seventh_crossing_returns_to_first_mod_eighteen_port :
    (ReturnFiberState.candidateNumber ⟨3, .positive⟩) % 18 = 1 := by
  decide

end Riemann
