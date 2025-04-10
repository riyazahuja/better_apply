import Lean.Meta.Tactic.LibrarySearch
import Lean.Meta.Tactic.TryThis
import Lean.Elab.Tactic.ElabTerm
import Mathlib.RingTheory.Ideal.Defs
import Mathlib.Data.Real.Basic


open Lean Meta LibrarySearch
open Elab Tactic Term TryThis

syntax (name := apply_better_stx) "apply_better" (" using " (colGt term),+)? : tactic

def sort_suggestions (suggestions :  Array (List MVarId × MetavarContext)) (mvar : MVarId): MetaM (Array MetavarContext) := do
  -- let mut sugg := []
  logInfo s!"HELLO"
  let sugg : MetaM _:= suggestions.mapM (fun (_, suggestionMCtx) => do
    withMCtx suggestionMCtx do
      let msg := (← instantiateMVars (mkMVar mvar)).headBeta
      let msg'← m!"{msg}".toString.toIO
      return (suggestionMCtx, msg'))
  -- for (_, suggestionMCtx) in suggestions do
  --   withMCtx suggestionMCtx do
  --     sugg := (suggestionMCtx, (← instantiateMVars (mkMVar mvar)).headBeta) :: sugg

  let sugg ← suggestions.mapM (fun (_, suggestionMCtx) => do
    withMCtx suggestionMCtx do
      let msg := (← instantiateMVars (mkMVar mvar)).headBeta
      let msg'← m!"{msg}".toString.toIO
      return (suggestionMCtx, msg'))

  -- Run the python script to get the sorting order
  let msgs := (sugg).map (fun (_, msg) => msg)
  let out ← IO.Process.output {
    cmd := "python3"
    args := #["BetterApply/sort_tactics.py", "hello"] ++ msgs.toList
  }

  logInfo s!"stdout: {out.stdout}"

  -- Parse the output to get the sorting indices
  let indices := (out.stdout.trim.split (· == '\n')).map (fun s => s.toNat!)

  -- Reorder the suggestions based on the indices
  let mut sorted := Array.empty
  for i in indices do
    if h : i < (sugg).size then
      sorted := sorted.push (sugg)[i].1

  if sorted.isEmpty then
    return (sugg).map (fun (x, _) => x)

  -- let sorted := (← sugg).insertionSort (fun (_, a) (_, b) => a<b) |>.map fun (x, _) => x

  return sorted

def exact_better (ref : Syntax) (required : Option (Array (TSyntax `term))):
    TacticM Unit := do
  let mvar ← getMainGoal
  -- let initialState ← saveState
  let (_, goal) ← (← getMainGoal).intros
  goal.withContext do
    let required := (← (required.getD #[]).mapM getFVarId).toList.map .fvar
    let tactic := fun exfalso =>
      solveByElim required (exfalso := exfalso) (maxDepth := 6)
    let allowFailure := fun g => do
      let g ← g.withContext (instantiateMVars (.mvar g))
      return required.all fun e => e.occurs g
    match (← librarySearch goal tactic allowFailure) with
    -- Found goal that closed problem
    | none =>
      addExactSuggestion ref (← instantiateMVars (mkMVar mvar)).headBeta-- (checkState? := initialState)
    -- Found suggestions
      logInfo m!"apply? found suggestion: {ref} {(← instantiateMVars (mkMVar mvar)).headBeta}"
    | some suggestions =>
      reportOutOfHeartbeats `apply? ref
      let suggestions' ← sort_suggestions suggestions mvar
      for suggestionMCtx in suggestions' do
        withMCtx suggestionMCtx do
          addExactSuggestion ref (← instantiateMVars (mkMVar mvar)).headBeta (addSubgoalsMsg := true) --(tacticErrorAsInfo := true)
          -- logInfo m!"apply? found suggestion: {ref} {(← instantiateMVars (mkMVar mvar)).headBeta}"
      if suggestions.isEmpty then logError "apply? didn't find any relevant lemmas"
      admitGoal goal


@[tactic apply_better_stx]
def evalApply' : Tactic := fun stx => do
  let `(tactic| apply_better $[using $[$required],*]?) := stx
        | throwUnsupportedSyntax
  exact_better (← getRef) required



-- example : ∀ (a b : Nat), a + b + 0 = 0 + (b + a) := by
--   apply_better


example : ∀ (n : Nat), n = n+1 := by
  apply_better


-- example (x y : ℝ) : Ideal.span {x} = Ideal.span {x^2} := by
--   apply_better


-- -- testing on a few examples from minif2f

-- theorem amc12a_2015_p10 (x y : ℤ) (h₀ : 0 < y) (h₁ : y < x) (h₂ : x + y + x * y = 80) : x = 26 := by
--   apply_better

-- theorem amc12a_2008_p8 (x y : ℝ) (h₀ : 0 < x ∧ 0 < y) (h₁ : y ^ 3 = 1)
--   (h₂ : 6 * x ^ 2 = 2 * (6 * y ^ 2)) : x ^ 3 = 2 * Real.sqrt 2 := by
--   apply_better

-- theorem mathd_algebra_182 (y : ℂ) : 7 * (3 * y + 2) = 21 * y + 14 := by
--   apply_better

-- theorem aime_1984_p5 (a b : ℝ) (h₀ : Real.logb 8 a + Real.logb 4 (b ^ 2) = 5)
--   (h₁ : Real.logb 8 b + Real.logb 4 (a ^ 2) = 7) : a * b = 512 := by
--   apply_better

-- theorem mathd_numbertheory_780 (m x : ℤ) (h₀ : 0 ≤ x) (h₁ : 10 ≤ m ∧ m ≤ 99) (h₂ : 6 * x % m = 1)
--   (h₃ : (x - 6 ^ 2) % m = 0) : m = 43 := by
--   apply_better

-- theorem mathd_algebra_116 (k x : ℝ) (h₀ : x = (13 - Real.sqrt 131) / 4)
--     (h₁ : 2 * x ^ 2 - 13 * x + k = 0) : k = 19 / 4 := by
--   rw [h₀] at h₁
--   rw [eq_comm.mp (add_eq_zero_iff_neg_eq.mp h₁)]
--   norm_num
--   rw [pow_two]
--   apply_better

-- theorem mathd_numbertheory_13 (u v : ℕ) (S : Set ℕ)
--   (h₀ : ∀ n : ℕ, n ∈ S ↔ 0 < n ∧ 14 * n % 100 = 46) (h₁ : IsLeast S u)
--   (h₂ : IsLeast (S \ {u}) v) : (u + v : ℚ) / 2 = 64 := by
--   apply_better

-- theorem amc12a_2009_p9 (a b c : ℝ) (f : ℝ → ℝ) (h₀ : ∀ x, f (x + 3) = 3 * x ^ 2 + 7 * x + 4)
--   (h₁ : ∀ x, f x = a * x ^ 2 + b * x + c) : a + b + c = 2 := by
--   apply_better
