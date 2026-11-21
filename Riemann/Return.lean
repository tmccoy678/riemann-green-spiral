namespace Riemann

/-- A point quantized to one million integer units per MATLAB coordinate unit. -/
structure MicroPoint where
  x : Int
  y : Int
  z : Int
  deriving DecidableEq, Repr

def squaredDistance (a b : MicroPoint) : Int :=
  (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2

/-- Path 22, MATLAB sample 1176 (one-based), quantized at 10⁻⁶. -/
def path22Before : MicroPoint :=
  ⟨110196112, 23287421, 4400549⟩

/-- Path 22, sample 1336: a point more than 3 units into the excursion. -/
def path22Far : MicroPoint :=
  ⟨113185550, 23969641, 4210346⟩

/-- Path 22, sample 1376: the trajectory has returned near sample 1176. -/
def path22After : MicroPoint :=
  ⟨110067375, 23297624, 4170377⟩

/--
The conservative return predicate used for Riemann: over 200 samples, the
trajectory leaves its earlier neighborhood by at least 3.0 coordinate units
and then returns within 0.3 units of the earlier point.
-/
def path22ReturnWitness : Prop :=
  1176 < 1336 ∧
  1336 < 1376 ∧
  200 ≤ 1376 - 1176 ∧
  9_000_000_000_000 ≤ squaredDistance path22Before path22Far ∧
  squaredDistance path22Before path22After ≤ 90_000_000_000

/-- Kernel-checked arithmetic witness for the observed return in path 22. -/
theorem path22_has_return_witness : path22ReturnWitness := by
  unfold path22ReturnWitness
  decide

/--
The scheduled target 1387 retains samples 1168–1387 in the 220-sample
MATLAB window, so all three witness samples are simultaneously displayable.
-/
def path22WitnessFitsRenderedWindow : Prop :=
  1387 - 220 < 1176 ∧ 1376 ≤ 1387

theorem path22_witness_fits_rendered_window :
    path22WitnessFitsRenderedWindow := by
  unfold path22WitnessFitsRenderedWindow
  decide

end Riemann
