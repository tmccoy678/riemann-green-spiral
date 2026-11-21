namespace Riemann

/--
MATLAB first reaches `target` samples of a source trajectory, then
`MaximumNumPoints` retains only the newest `capacity` samples.
-/
def reveal (capacity target : Nat) (path : List α) : List α :=
  let reached := path.take target
  reached.drop (reached.length - capacity)

/-- The rolling display cannot fabricate a sample absent from its source path. -/
theorem reveal_no_fabricated_points {point : α}
    {capacity target : Nat} {path : List α}
    (h : point ∈ reveal capacity target path) : point ∈ path := by
  have reached : point ∈ path.take target := by
    exact List.mem_of_mem_drop h
  exact List.mem_of_mem_take reached

/-- The visible window contains the smaller of its capacity and reached length. -/
theorem reveal_length (capacity target : Nat) (path : List α) :
    (reveal capacity target path).length =
      min (path.take target).length capacity := by
  unfold reveal
  rw [List.length_drop]
  exact Nat.sub_sub_eq_min _ _

/-- Before the rolling capacity is filled, the entire reached prefix is visible. -/
theorem reveal_before_capacity {capacity target : Nat} {path : List α}
    (h : (path.take target).length ≤ capacity) :
    reveal capacity target path = path.take target := by
  change (path.take target).drop ((path.take target).length - capacity) =
    path.take target
  rw [Nat.sub_eq_zero_of_le h]
  exact List.drop_zero

/--
Any property established for every source sample—field bounds, finiteness,
provenance, or another audit predicate—also holds for every rendered sample.
-/
theorem reveal_preserves_property {property : α → Prop}
    {capacity target : Nat} {path : List α}
    (source_has_property : ∀ point ∈ path, property point) :
    ∀ point ∈ reveal capacity target path, property point := by
  intro point rendered
  exact source_has_property point (reveal_no_fabricated_points rendered)

end Riemann
