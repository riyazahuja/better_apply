prelude
import Lean.Meta.Tactic.LibrarySearch
import Lean.Meta.Tactic.TryThis
import Lean.Elab.Tactic.ElabTerm



open Lean Meta LibrarySearch
open Elab Tactic Term TryThis

syntax (name := apply_better_stx) "apply_better" (" using " (colGt term),+)? : tactic

def sort_suggestions (suggestions :  Array (List MVarId × MetavarContext)) (mvar : MVarId): MetaM (Array MetavarContext) := do
  -- let mut sugg := []
  let sugg : MetaM _:= suggestions.mapM (fun (_, suggestionMCtx) => do
    withMCtx suggestionMCtx do
      let msg := (← instantiateMVars (mkMVar mvar)).headBeta
      let msg'← m!"{msg}".toString.toIO
      return (suggestionMCtx, msg'))
  -- for (_, suggestionMCtx) in suggestions do
  --   withMCtx suggestionMCtx do
  --     sugg := (suggestionMCtx, (← instantiateMVars (mkMVar mvar)).headBeta) :: sugg

  let sorted := (← sugg).insertionSort (fun (_, a) (_, b) => a<b) |>.map fun (x, _) => x

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
          logInfo m!"apply? found suggestion: {ref} {(← instantiateMVars (mkMVar mvar)).headBeta}"
      if suggestions.isEmpty then logError "apply? didn't find any relevant lemmas"
      admitGoal goal


@[tactic apply_better_stx]
def evalApply' : Tactic := fun stx => do
  let `(tactic| apply_better $[using $[$required],*]?) := stx
        | throwUnsupportedSyntax
  exact_better (← getRef) required



example : ∀ (a b : Nat), a + b = b + a := by
  apply_better


example : ∀ (n : Nat), n = n+1 := by
  apply_better
