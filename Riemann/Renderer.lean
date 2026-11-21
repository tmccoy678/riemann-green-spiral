namespace Riemann

/-- The renderer exposes the first `frame` samples of a source trajectory. -/
def reveal (frame : Nat) (path : List α) : List α :=
  path.take frame

/-- Every rendered frame is literally a prefix of its MATLAB source path. -/
theorem reveal_is_prefix (frame : Nat) (path : List α) :
    reveal frame path <+: path := by
  exact List.take_prefix frame path

/-- The renderer cannot fabricate a sample absent from the source path. -/
theorem reveal_no_fabricated_points {point : α} {frame : Nat} {path : List α}
    (h : point ∈ reveal frame path) : point ∈ path := by
  exact List.mem_of_mem_take h

/-- A frame exposes exactly the smaller of its index and the path length. -/
theorem reveal_length (frame : Nat) (path : List α) :
    (reveal frame path).length = min frame path.length := by
  exact List.length_take

/-- At or beyond the source length, the complete trajectory is visible. -/
theorem reveal_complete {frame : Nat} {path : List α}
    (h : path.length ≤ frame) : reveal frame path = path := by
  exact List.take_of_length_le h

/--
Any property established for every source sample—field bounds, finiteness,
provenance, or another audit predicate—also holds for every rendered sample.
-/
theorem reveal_preserves_property {property : α → Prop}
    {frame : Nat} {path : List α}
    (source_has_property : ∀ point ∈ path, property point) :
    ∀ point ∈ reveal frame path, property point := by
  intro point rendered
  exact source_has_property point (reveal_no_fabricated_points rendered)

end Riemann
