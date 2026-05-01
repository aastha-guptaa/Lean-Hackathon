import Chess.Model

open Piece
open Colour

-- 1. An empty board has no pseudo-legal moves
def emptyBoard : Board :=
  #v[
    #v[none, none, none, none, none, none, none, none],
    #v[none, none, none, none, none, none, none, none],
    #v[none, none, none, none, none, none, none, none],
    #v[none, none, none, none, none, none, none, none],
    #v[none, none, none, none, none, none, none, none],
    #v[none, none, none, none, none, none, none, none],
    #v[none, none, none, none, none, none, none, none],
    #v[none, none, none, none, none, none, none, none]
  ]

def emptyState : GameState := {
  board := emptyBoard,
  turn := white,
  castling := {},
  enPassant := none,
  valid := true,
  moveNum := 0,
  history := []
}

theorem empty_board_no_moves (move : Move) :
  isPseudoLegalMove emptyState move = false := by
  -- We unfold the definitions to show the board is completely empty
  unfold isPseudoLegalMove
  sorry

-- 2. A player can't capture their own piece
theorem no_friendly_fire (state : GameState) (move : Move) :
  isPseudoLegalMove state move = true →
  match state.board.getSquare move.toPos with
  | some cp => cp.colour ≠ state.turn
  | none => true := by
  sorry

-- 3. A knight always has at most 8 possible moves
-- (We formulate this by showing there are at most 8 positions `toPos` where `isValidKnightMove fromPos toPos` is true)
-- This is hard to state with lists without defining list of all squares.

-- 4. A pawn never moves backwards
theorem pawn_always_moves_forward (state : GameState) (move : Move) :
  state.turn = white →
  isValidPawnMove state move = true →
  move.toPos.row.val > move.colourPiecePos.pos.row.val := by
  sorry

-- 5. A bishop always stays on the same colour square
theorem bishop_stays_on_colour (board : Board) (fromPos toPos : Pos) :
  isValidBishopMove board fromPos toPos = true →
  (fromPos.row.val + fromPos.col.val) % 2 = (toPos.row.val + toPos.col.val) % 2 := by
  sorry

-- 6. Pawn Promotion Validation
theorem pawn_promotion_always_on_promo_row (state : GameState) (move : Move) :
  isValidPawnMove state move = true →
  move.promotion.isSome = true →
  (state.turn = white → move.toPos.row.val = 7) ∧
  (state.turn = black → move.toPos.row.val = 0) := by
  -- By definition in `isValidPawnMove`, `validPromo` is only true if `toPos.row.val == promoRow`
  -- when `move.promotion` is `some`.
  sorry

