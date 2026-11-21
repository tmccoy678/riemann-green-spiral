import Riemann.Return

namespace Riemann

/-- A velocity vector quantized to one million integer units. -/
structure MicroVector where
  x : Int
  y : Int
  z : Int
  deriving DecidableEq, Repr

def squaredMagnitude (v : MicroVector) : Int :=
  v.x ^ 2 + v.y ^ 2 + v.z ^ 2

/-- Path 22, MATLAB sample 1601, quantized at 10⁻⁶. -/
def path22ReturnTwo : MicroPoint :=
  ⟨109923256, 23291677, 3947771⟩

/-- Path 22, MATLAB sample 1770, quantized at 10⁻⁶. -/
def path22ReturnThree : MicroPoint :=
  ⟨109743260, 23359119, 3803687⟩

/--
Three finite sampled returns in the preserved path-22 channel. This is a
statement about exact exported samples, not an infinite convergence claim.
-/
def path22ThreeReturnCertificate : Prop :=
  1176 < 1376 ∧
  1376 < 1601 ∧
  1601 < 1770 ∧
  squaredDistance path22Before path22After = 69_656_465_962 ∧
  squaredDistance path22After path22ReturnTwo = 70_359_084_206 ∧
  squaredDistance path22ReturnTwo path22ReturnThree = 57_707_182_436 ∧
  squaredDistance path22Before path22After ≤ 90_000_000_000 ∧
  squaredDistance path22After path22ReturnTwo ≤ 90_000_000_000 ∧
  squaredDistance path22ReturnTwo path22ReturnThree ≤ 90_000_000_000

theorem path22_has_three_sampled_returns :
    path22ThreeReturnCertificate := by
  unfold path22ThreeReturnCertificate
  decide

/--
Rust's complete-row audit identifies sample 1230 as the minimum sampled speed
in samples 1176–1770. This is its quantized velocity certificate.
-/
def path22CorridorMinimumVelocity : MicroVector :=
  ⟨-1886341, 2128249, -31635⟩

def path22CorridorNonstagnationCertificate : Prop :=
  squaredMagnitude path22CorridorMinimumVelocity = 8_088_726_947_507 ∧
  7_840_000_000_000 ≤ squaredMagnitude path22CorridorMinimumVelocity

theorem path22_corridor_certificate_nonstagnant :
    path22CorridorNonstagnationCertificate := by
  unfold path22CorridorNonstagnationCertificate
  decide

/-- Path 22, sample 2605: Rust's complete-row minimum-z certificate. -/
def path22RecordedMinimumZPoint : MicroPoint :=
  ⟨119887631, 25564738, 3361277⟩

def path22RecordedMinimumZCertificate : Prop :=
  path22RecordedMinimumZPoint.z = 3_361_277 ∧
  3_300_000 ≤ path22RecordedMinimumZPoint.z

theorem path22_recorded_min_z_certificate_above_3_3 :
    path22RecordedMinimumZCertificate := by
  unfold path22RecordedMinimumZCertificate
  decide

/-- Path 22's final recorded sample, immediately inside the field boundary. -/
def path22Endpoint : MicroPoint :=
  ⟨115073580, 17552947, 3361768⟩

def path22FieldLowerY : Int := 17_499_901

def path22BoundaryExitCertificate : Prop :=
  path22Endpoint.y - path22FieldLowerY = 53_046 ∧
  0 ≤ path22Endpoint.y - path22FieldLowerY ∧
  path22Endpoint.y - path22FieldLowerY < 60_000 ∧
  3_300_000 ≤ path22Endpoint.z

theorem path22_endpoint_near_lower_y_boundary :
    path22BoundaryExitCertificate := by
  unfold path22BoundaryExitCertificate path22FieldLowerY
  decide

/-- The measured MATLAB field box, quantized at 10⁻⁶. -/
def insideMeasuredField (point : MicroPoint) : Prop :=
  70_187_890 ≤ point.x ∧ point.x ≤ 134_299_890 ∧
  17_499_901 ≤ point.y ∧ point.y ≤ 59_999_901 ∧
  -2_000 ≤ point.z ∧ point.z ≤ 16_000_000

theorem path22_endpoint_is_inside_measured_field :
    insideMeasuredField path22Endpoint := by
  unfold insideMeasuredField path22Endpoint
  decide

/--
No exterior velocity is assigned. Rust rejects any committed sample outside
the measured box; Lean therefore carries no implicit boundary extension.
-/
def path22ExteriorVelocity : Option MicroVector :=
  none

theorem path22_has_no_assumed_exterior_velocity :
    path22ExteriorVelocity = none := by
  rfl

/--
The closest other-path/channel pair found by the complete Rust search:
path 29 sample 207 and path 22 sample 1191.
-/
def closestOtherPathPoint : MicroPoint :=
  ⟨111440711, 26424889, 7967842⟩

def closestPath22ChannelPoint : MicroPoint :=
  ⟨111637323, 24892345, 4375207⟩

def path22ExclusionCertificate : Prop :=
  squaredDistance closestOtherPathPoint closestPath22ChannelPoint =
      15_294_373_633_705 ∧
  4_000_000_000_000 <
      squaredDistance closestOtherPathPoint closestPath22ChannelPoint

theorem path22_exclusion_certificate_above_two :
    path22ExclusionCertificate := by
  unfold path22ExclusionCertificate
  decide

/--
Rust's complete audit of the 33×33 seed neighborhood. The counts describe a
finite geometric recurrence basin; they do not assert interaction or energy
transfer between streamlines.
-/
def path22NeighborhoodCertificate : Prop :=
  let seedCount := 1089
  let returnCount := 313
  let withinPointThree := 305
  let withinPointFive := 306
  let withinOne := 309
  let withinTwo := 312
  let lowerYExitCount := 1089
  seedCount = 33 * 33 ∧
  returnCount < seedCount ∧
  withinPointThree ≤ withinPointFive ∧
  withinPointFive ≤ withinOne ∧
  withinOne ≤ withinTwo ∧
  withinTwo < seedCount ∧
  lowerYExitCount = seedCount

theorem path22_neighborhood_certificate :
    path22NeighborhoodCertificate := by
  unfold path22NeighborhoodCertificate
  decide

/--
The finite field ends at the recorded boundary. Outside-field continuation,
including genuine disappearance, is deliberately not chosen by this artifact.
-/
inductive PostFieldOutcome where
  | continues
  | disappears
  | unresolved
  deriving DecidableEq, Repr

def path22PostFieldOutcome : PostFieldOutcome :=
  .unresolved

theorem path22_post_field_outcome_is_unresolved :
    path22PostFieldOutcome = .unresolved := by
  rfl

end Riemann
