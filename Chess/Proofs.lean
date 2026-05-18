import Chess.Model
import Chess.LegalProofs

namespace Chess

/-- A valid target square can never contain a friendly piece. -/
theorem no_friendly_fire
  (board : Board)
  (toPos : Pos)
  (c : Colour)
  (h : isValidTarget board c toPos = true) :
  match board.getSquare toPos with
  | some cp => cp.colour ≠ c
  | none => True := by
  cases hsq : board.getSquare toPos with
  | none =>
      simp
  | some cp =>
      have hneq : (cp.colour != c) = true := by
        simpa [isValidTarget, hsq] using h
      have hne : cp.colour ≠ c := by
        intro hEq
        have hFalse : (cp.colour != c) = false := by
          have hcc : (c != c) = false := by
            cases c <;> decide
          simpa [hEq] using hcc
        rw [hFalse] at hneq
        cases hneq
      exact hne

/-- Bishop moves preserve square colour (checkerboard parity). -/
theorem bishop_stays_on_colour
  (board : Board)
  (fromPos toPos : Pos)
  (h : isValidBishopMove board fromPos toPos = true) :
  (fromPos.row.val + fromPos.col.val) % 2 = (toPos.row.val + toPos.col.val) % 2 := by
  let dc : Int := posDist toPos.col fromPos.col
  let dr : Int := posDist toPos.row fromPos.row

  have hCore :
      dc.natAbs = dr.natAbs ∧ dc ≠ 0 ∧ isPathClear board fromPos toPos = true := by
    simpa [isValidBishopMove, dc, dr, Bool.and_eq_true, and_assoc] using h
  have hAbs : dc.natAbs = dr.natAbs := hCore.1

  have hsign : dc = dr ∨ dc = -dr := by
    exact Int.natAbs_eq_natAbs_iff.mp hAbs

  let fromSum : Nat := fromPos.row.val + fromPos.col.val
  let toSum : Nat := toPos.row.val + toPos.col.val

  have hcast : ((fromSum % 2 : Nat) : Int) = ((toSum % 2 : Nat) : Int) := by
    rw [Int.natCast_emod, Int.natCast_emod]
    cases hsign with
    | inl hsame =>
        have hEqDelta :
            ((toPos.col.val : Int) - (fromPos.col.val : Int)) =
            ((toPos.row.val : Int) - (fromPos.row.val : Int)) := by
          simpa [dc, dr, posDist] using hsame
        have hDiffMod : (((toSum : Int) - (fromSum : Int)) % 2) = 0 := by
          unfold toSum fromSum
          omega
        have hEqMod : ((toSum : Int) % 2) = ((fromSum : Int) % 2) := by
          exact (Int.emod_eq_emod_iff_emod_sub_eq_zero).2 hDiffMod
        simpa [eq_comm] using hEqMod
    | inr hop =>
        have hEqDelta :
            ((toPos.col.val : Int) - (fromPos.col.val : Int)) =
            -((toPos.row.val : Int) - (fromPos.row.val : Int)) := by
          simpa [dc, dr, posDist] using hop
        have hDiff : ((toSum : Int) - (fromSum : Int)) = 0 := by
          unfold toSum fromSum
          omega
        have hDiffMod : (((toSum : Int) - (fromSum : Int)) % 2) = 0 := by
          simpa [hDiff]
        have hEqMod : ((toSum : Int) % 2) = ((fromSum : Int) % 2) := by
          exact (Int.emod_eq_emod_iff_emod_sub_eq_zero).2 hDiffMod
        simpa [eq_comm] using hEqMod

  exact (Int.natCast_inj.mp hcast)

end Chess
