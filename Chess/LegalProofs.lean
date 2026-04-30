import Chess.Model
import Chess.Legal

namespace Chess

-- ------------------------------------------
-- makeMove: valid branch
-- ------------------------------------------

theorem makeMove_history_of_pseudoLegal
  (s : GameState) (m : Move)
  (h : isPseudoLegalMove s m = true) :
  (s.makeMove m).history = m :: s.history := by
  unfold GameState.makeMove
  simp [h]

theorem makeMove_turn_of_pseudoLegal
  (s : GameState) (m : Move)
  (h : isPseudoLegalMove s m = true) :
  (s.makeMove m).turn = s.turn.opponent := by
  unfold GameState.makeMove
  simp [h]

theorem makeMove_moveNum_of_pseudoLegal
  (s : GameState) (m : Move)
  (h : isPseudoLegalMove s m = true) :
  (s.makeMove m).moveNum = s.moveNum + 1 := by
  unfold GameState.makeMove
  simp [h]

theorem makeMove_validFlag_of_pseudoLegal
  (s : GameState) (m : Move)
  (h : isPseudoLegalMove s m = true) :
  (s.makeMove m).valid = true := by
  unfold GameState.makeMove
  simp [h]

-- ------------------------------------------
-- makeMove: invalid branch (non-destructive except valid flag)
-- ------------------------------------------

theorem makeMove_validFlag_of_not_pseudoLegal
  (s : GameState) (m : Move)
  (h : isPseudoLegalMove s m = false) :
  (s.makeMove m).valid = false := by
  unfold GameState.makeMove
  simp [h]

theorem makeMove_turn_of_not_pseudoLegal
  (s : GameState) (m : Move)
  (h : isPseudoLegalMove s m = false) :
  (s.makeMove m).turn = s.turn := by
  unfold GameState.makeMove
  simp [h]

theorem makeMove_board_of_not_pseudoLegal
  (s : GameState) (m : Move)
  (h : isPseudoLegalMove s m = false) :
  (s.makeMove m).board = s.board := by
  unfold GameState.makeMove
  simp [h]

theorem makeMove_history_of_not_pseudoLegal
  (s : GameState) (m : Move)
  (h : isPseudoLegalMove s m = false) :
  (s.makeMove m).history = s.history := by
  unfold GameState.makeMove
  simp [h]

theorem makeMove_moveNum_of_not_pseudoLegal
  (s : GameState) (m : Move)
  (h : isPseudoLegalMove s m = false) :
  (s.makeMove m).moveNum = s.moveNum := by
  unfold GameState.makeMove
  simp [h]

theorem makeMove_castling_of_not_pseudoLegal
  (s : GameState) (m : Move)
  (h : isPseudoLegalMove s m = false) :
  (s.makeMove m).castling = s.castling := by
  unfold GameState.makeMove
  simp [h]

theorem makeMove_enPassant_of_not_pseudoLegal
  (s : GameState) (m : Move)
  (h : isPseudoLegalMove s m = false) :
  (s.makeMove m).enPassant = s.enPassant := by
  unfold GameState.makeMove
  simp [h]

-- ------------------------------------------
-- attack/check interfaces
-- ------------------------------------------

theorem isInCheck_eq_attackedKingSquare
  (s : GameState) (c : Colour) (k : Pos)
  (h : findKing s.board c = some k) :
  isInCheck s c = isSquareAttacked s.board c.opponent k := by
  unfold isInCheck
  simp [h]

-- ------------------------------------------
-- castling helper consequences
-- ------------------------------------------

theorem castlePathSafe_implies_hasRook
  (s : GameState) (m : Move)
  (hCastle : isCastlingMove m = true)
  (hSafe : castlePathSafe s m = true) :
  hasCastlingRook s m = true := by
  sorry

theorem castlePathSafe_implies_startSafe
  (s : GameState) (m : Move)
  (hCastle : isCastlingMove m = true)
  (hSafe : castlePathSafe s m = true) :
  let fromPos := m.colourPiecePos.pos
  let mover := m.colourPiecePos.colourPiece.colour
  isSquareAttacked s.board mover.opponent fromPos = false := by
  sorry

theorem castlePathSafe_implies_midSafe
  (s : GameState) (m : Move)
  (hCastle : isCastlingMove m = true)
  (hSafe : castlePathSafe s m = true) :
  let fromPos := m.colourPiecePos.pos
  let toPos := m.toPos
  let mover := m.colourPiecePos.colourPiece.colour
  let dc := posDist toPos.col fromPos.col
  let step : Int := if dc > 0 then 1 else -1
  let midColInt : Int := (fromPos.col.val : Int) + step
  match intToFin8 midColInt with
  | some midCol =>
      isSquareAttacked s.board mover.opponent { row := fromPos.row, col := midCol } = false
  | none => False := by
  sorry

-- ------------------------------------------
-- legal move core
-- ------------------------------------------

theorem legal_implies_pseudoLegal
  (s : GameState) (m : Move)
  (h : isLegalMove s m = true) :
  isPseudoLegalMove s m = true := by
  unfold isLegalMove at h
  by_cases hp : isPseudoLegalMove s m
  · simpa [hp] using hp
  · simp [hp] at h

theorem legal_implies_kingSafeAfter
  (s : GameState) (m : Move)
  (h : isLegalMove s m = true) :
  isInCheck (s.makeMove m) s.turn = false := by
  sorry

theorem legal_castling_implies_castlePathSafe
  (s : GameState) (m : Move)
  (hLegal : isLegalMove s m = true)
  (hCastle : isCastlingMove m = true) :
  castlePathSafe s m = true := by
  sorry

-- ------------------------------------------
-- castling history specialization
-- ------------------------------------------

theorem castling_history_prepends_move
  (s : GameState) (m : Move)
  (_hCastle : isCastlingMove m = true)
  (hPseudo : isPseudoLegalMove s m = true) :
  (s.makeMove m).history = m :: s.history := by
  exact makeMove_history_of_pseudoLegal s m hPseudo

end Chess
