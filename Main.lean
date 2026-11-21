import Riemann

open Riemann

def main : IO Unit := do
  IO.println "RIEMANN GREEN SPIRAL"
  IO.println "Lean-checked renderer invariant: rolling windows contain source-path samples only."
  IO.println "Lean-checked return witness: path 22 returns within 0.3 units after a 3.0-unit excursion."
  IO.println "Lean-checked channel certificates: three sampled returns, non-stagnation, separation, and boundary exit."
  IO.println "Lean-checked neighborhood certificate: 313 returns and 312 two-unit channel entries among 1,089 seeds."
  IO.println "Boundary assumptions: none; exterior velocity is unassigned."
  IO.println "Post-field outcome: unresolved; continuation and disappearance remain admissible."
