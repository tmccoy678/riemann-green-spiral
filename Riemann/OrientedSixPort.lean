import Riemann.Mod18Boundary

namespace Riemann

/-- The ordered root frame. Its mirror exchanges ground and identity sides. -/
inductive RootOrientation where
  | zeroOne
  | oneZero
  deriving DecidableEq, Repr

def RootOrientation.mirror : RootOrientation → RootOrientation
  | .zeroOne => .oneZero
  | .oneZero => .zeroOne

theorem RootOrientation.mirror_involution (root : RootOrientation) :
    root.mirror.mirror = root := by
  cases root <;> rfl

/-- One step backward in the ordered six-port cycle. -/
def UnitModEighteen.previous : UnitModEighteen → UnitModEighteen
  | .one => .seventeen
  | .five => .one
  | .seven => .five
  | .eleven => .seven
  | .thirteen => .eleven
  | .seventeen => .thirteen

theorem UnitModEighteen.next_previous (port : UnitModEighteen) :
    port.next.previous = port := by
  cases port <;> rfl

theorem UnitModEighteen.previous_next (port : UnitModEighteen) :
    port.previous.next = port := by
  cases port <;> rfl

/-- One oriented state: a root handedness and one of the six arithmetic ports. -/
structure OrientedSixPortState where
  root : RootOrientation
  port : UnitModEighteen
  deriving DecidableEq, Repr

namespace OrientedSixPortState

def advance (state : OrientedSixPortState) : OrientedSixPortState :=
  ⟨state.root, state.port.next⟩

def previous (state : OrientedSixPortState) : OrientedSixPortState :=
  ⟨state.root, state.port.previous⟩

def mirror (state : OrientedSixPortState) : OrientedSixPortState :=
  ⟨state.root.mirror, state.port.negate⟩

def advanceSix (state : OrientedSixPortState) : OrientedSixPortState :=
  state.advance.advance.advance.advance.advance.advance

/-- `T⁶ = I`: one complete six-port bar returns to the same oriented state. -/
theorem advance_six_returns (state : OrientedSixPortState) :
    state.advanceSix = state := by
  cases state with
  | mk root port => cases root <;> cases port <;> rfl

/-- `M² = I`: mirroring twice restores both root and port. -/
theorem mirror_involution (state : OrientedSixPortState) :
    state.mirror.mirror = state := by
  cases state with
  | mk root port => cases root <;> cases port <;> rfl

/-- `MTM = T⁻¹`: the mirror conjugates forward advance to backward advance. -/
theorem mirror_advance_mirror (state : OrientedSixPortState) :
    state.mirror.advance.mirror = state.previous := by
  cases state with
  | mk root port => cases root <;> cases port <;> rfl

end OrientedSixPortState

/-- The three `+2` crossings, including the final return through `19 ≡ 1`. -/
def modEighteenTwoCrossings : List (Nat × Nat) :=
  [(5, 7), (11, 13), (17, 19)]

theorem all_three_two_crossings_are_exact :
    modEighteenTwoCrossings.map (fun pair => pair.2 - pair.1) = [2, 2, 2] := by
  decide

theorem final_two_crossing_returns_home :
    19 % 18 = 1 := by
  decide

/-- A dependency-free exact ratio, represented by numerator and denominator. -/
structure ExactRatio where
  numerator : Nat
  denominator : Nat
  deriving DecidableEq, Repr

def ExactRatio.reciprocal (ratio : ExactRatio) : ExactRatio :=
  ⟨ratio.denominator, ratio.numerator⟩

def canonicalPrimalMassScale : ExactRatio := ⟨57, 14⟩

def canonicalDualActionScale : ExactRatio := ⟨14, 57⟩

/-- The canonical primal and dual scales are exact reciprocals. -/
theorem canonical_primal_dual_reciprocal :
    canonicalPrimalMassScale.reciprocal = canonicalDualActionScale := by
  rfl

/-- Cross-multiplication certifies that the reciprocal product is exactly one. -/
theorem canonical_primal_dual_product :
    canonicalPrimalMassScale.numerator * canonicalDualActionScale.numerator =
      canonicalPrimalMassScale.denominator * canonicalDualActionScale.denominator := by
  decide

end Riemann
