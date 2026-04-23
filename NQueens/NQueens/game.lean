import Mathlib.Data.Fin.Basic
import Mathlib.Data.List.Basic

/-!
# VerifiedQueens Game Engine (N x M Board)
This module defines a rectangular board, the region constraints, and the strict
rules for valid moves in the region-based Queens logic puzzle.
-/

-- We define separate dimensions for rows, columns, and total regions.
def numRows : Nat := 8
def numCols : Nat := 10
def numRegions : Nat := 8

/-- A coordinate on an N x M board. We use Fin to guarantee at compile-time
    that pieces cannot be placed out of bounds for either axis. -/
structure Pos where
  row : Fin numRows
  col : Fin numCols
deriving DecidableEq, Repr

/-- A RegionMap assigns a distinct region ID to every cell on the board. -/
def RegionMap := Pos → Fin numRegions

/-- The board state is simply the history of queens successfully placed. -/
abbrev BoardState := List Pos

/-! ## The Core Constraints -/

/-! ## The Core Constraints -/

/-- Rule 1 & 2: Queens cannot share the same row or column. -/
abbrev shareRowOrCol (p1 p2 : Pos) : Prop :=
  p1.row = p2.row ∨ p1.col = p2.col

/-- Rule 3: Queens cannot touch, even diagonally.
    Using `(a - b) + (b - a)` is a native, import-free way to compute
    absolute difference for natural numbers in Lean. -/
abbrev isAdjacent (p1 p2 : Pos) : Prop :=
  ((p1.row.val - p2.row.val) + (p2.row.val - p1.row.val) ≤ 1) ∧
  ((p1.col.val - p2.col.val) + (p2.col.val - p1.col.val) ≤ 1)

/-- Rule 4: Queens cannot be in the same colored region. -/
abbrev shareRegion (regions : RegionMap) (p1 p2 : Pos) : Prop :=
  regions p1 = regions p2

/-- A helper predicate combining all collision types.
    Because this is an `abbrev`, Lean can "see through" it during proof synthesis. -/
abbrev conflicts (regions : RegionMap) (p1 p2 : Pos) : Prop :=
  shareRowOrCol p1 p2 ∨ isAdjacent p1 p2 ∨ shareRegion regions p1 p2


/-! ## The Verification Gate -/

/-- The master safety invariant. A move is valid if and only if the new position
    does not conflict with ANY queen currently on the board. -/
def IsValidMove (regions : RegionMap) (state : BoardState) (new_pos : Pos) : Prop :=
  ∀ q ∈ state, ¬ conflicts regions q new_pos

-- Allows Lean to automatically compute if a move is valid.
instance (regions : RegionMap) (state : BoardState) (new_pos : Pos) :
  Decidable (IsValidMove regions state new_pos) :=
  by
    unfold IsValidMove
    infer_instance

/-! ## The Agent Transition Monad -/

/-- Safely transitions the board to a new state ONLY if the move is mathematically valid. -/
def makeSafeMove (regions : RegionMap) (state : BoardState) (new_pos : Pos) : Option BoardState :=
  if IsValidMove regions state new_pos then
    some (new_pos :: state)
  else
    none
