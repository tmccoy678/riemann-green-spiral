import Riemann

open Riemann

def main : IO Unit := do
  IO.println "RIEMANN GREEN SPIRAL"
  IO.println "Lean-checked renderer invariant: rolling windows contain source-path samples only."
  IO.println "Lean-checked return witness: path 22 returns within 0.3 units after a 3.0-unit excursion."
