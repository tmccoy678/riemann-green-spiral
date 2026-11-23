namespace Riemann

/-- The two measured orientations of the return section. -/
inductive SectionOrientation where
  | positive
  | negative
  deriving DecidableEq, Repr

/-- Every one of the first nine measured crossings alternates orientation. -/
def SectionOrientation.flip : SectionOrientation → SectionOrientation
  | .positive => .negative
  | .negative => .positive

/-- The two units modulo six, represented without importing extra algebra. -/
inductive UnitModSix where
  | one
  | five
  deriving DecidableEq, Repr

def UnitModSix.value : UnitModSix → Nat
  | .one => 1
  | .five => 5

/-- Multiplication by `-1 = 5 mod 6` exchanges the two units. -/
def UnitModSix.negate : UnitModSix → UnitModSix
  | .one => .five
  | .five => .one

theorem UnitModSix.negate_is_multiply_by_five (residue : UnitModSix) :
    (5 * residue.value) % 6 = residue.negate.value := by
  cases residue <;> decide

/-- The pointed, orientation-preserving map selected by the measured order. -/
def orientationResidue : SectionOrientation → UnitModSix
  | .positive => .one
  | .negative => .five

theorem orientationResidue_commutes_with_flip (orientation : SectionOrientation) :
    orientationResidue orientation.flip =
      (orientationResidue orientation).negate := by
  cases orientation <;> rfl

/--
Once the first positive crossing is fixed as the arithmetic identity, the
flip-commuting map is unique.
-/
theorem orientationResidue_unique
    (candidate : SectionOrientation → UnitModSix)
    (basepoint : candidate .positive = .one)
    (commutes : ∀ orientation,
      candidate orientation.flip = (candidate orientation).negate) :
    ∀ orientation, candidate orientation = orientationResidue orientation := by
  intro orientation
  cases orientation with
  | positive => exact basepoint
  | negative =>
      have step := commutes SectionOrientation.positive
      simpa [SectionOrientation.flip, UnitModSix.negate, basepoint,
        orientationResidue] using step

/-- The principal character of the two units modulo six. -/
def UnitModSix.principalCharacter : UnitModSix → Int
  | .one => 1
  | .five => 1

/-- The nontrivial character of the two units modulo six. -/
def UnitModSix.signCharacter : UnitModSix → Int
  | .one => 1
  | .five => -1

theorem principalCharacter_is_flip_invariant (residue : UnitModSix) :
    residue.negate.principalCharacter = residue.principalCharacter := by
  cases residue <;> rfl

theorem signCharacter_is_flip_antisymmetric (residue : UnitModSix) :
    residue.negate.signCharacter = -residue.signCharacter := by
  cases residue <;> rfl

/-- Pull an arithmetic character back through the measured orientation map. -/
def pullCharacter (character : UnitModSix → Int) : SectionOrientation → Int :=
  fun orientation => character (orientationResidue orientation)

theorem pulled_principal_character_has_eigenvalue_one
    (orientation : SectionOrientation) :
    pullCharacter UnitModSix.principalCharacter orientation.flip =
      pullCharacter UnitModSix.principalCharacter orientation := by
  cases orientation <;> rfl

theorem pulled_sign_character_has_eigenvalue_negative_one
    (orientation : SectionOrientation) :
    pullCharacter UnitModSix.signCharacter orientation.flip =
      -pullCharacter UnitModSix.signCharacter orientation := by
  cases orientation <;> rfl

/-- The measured first-nine-crossing orientation word. -/
def firstNineOrientations : List SectionOrientation :=
  [.positive, .negative, .positive, .negative, .positive,
   .negative, .positive, .negative, .positive]

def returnEnsembleOrientationCertificate : Prop :=
  firstNineOrientations.length = 9 ∧
  firstNineOrientations.head? = some .positive ∧
  firstNineOrientations.map orientationResidue =
    [.one, .five, .one, .five, .one, .five, .one, .five, .one]

theorem return_ensemble_has_pointed_mod_six_orientation_certificate :
    returnEnsembleOrientationCertificate := by
  unfold returnEnsembleOrientationCertificate firstNineOrientations
    orientationResidue
  decide

end Riemann
