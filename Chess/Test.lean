import Chess.Model

-- ==========================================
-- Helper to create pieces quickly
-- ==========================================

def wp (p : Piece) : Square := some { piece := p, colour := Colour.white }
def bp (p : Piece) : Square := some { piece := p, colour := Colour.black }
def em : Square := none

-- ==========================================
-- Standard starting chess board
-- Row 0 = White's back rank (row index 0)
-- Row 7 = Black's back rank (row index 7)
-- Col 0 = a-file, Col 7 = h-file
-- ==========================================

def startingBoard : Board :=
  -- Board is COLUMN-major: outer index = col (a=0..h=7), inner index = row (0..7)
  -- getSquare does board.get pos.col, then .get pos.row
  #v[
    -- Col 0 (a-file): rook(w), pawn(w), empty×4, pawn(b), rook(b)
    #v[ wp .rook, wp .pawn, em, em, em, em, bp .pawn, bp .rook ],
    -- Col 1 (b-file): knight(w), pawn(w), empty×4, pawn(b), knight(b)
    #v[ wp .knight, wp .pawn, em, em, em, em, bp .pawn, bp .knight ],
    -- Col 2 (c-file): bishop(w), pawn(w), empty×4, pawn(b), bishop(b)
    #v[ wp .bishop, wp .pawn, em, em, em, em, bp .pawn, bp .bishop ],
    -- Col 3 (d-file): queen(w), pawn(w), empty×4, pawn(b), queen(b)
    #v[ wp .queen, wp .pawn, em, em, em, em, bp .pawn, bp .queen ],
    -- Col 4 (e-file): king(w), pawn(w), empty×4, pawn(b), king(b)
    #v[ wp .king, wp .pawn, em, em, em, em, bp .pawn, bp .king ],
    -- Col 5 (f-file): bishop(w), pawn(w), empty×4, pawn(b), bishop(b)
    #v[ wp .bishop, wp .pawn, em, em, em, em, bp .pawn, bp .bishop ],
    -- Col 6 (g-file): knight(w), pawn(w), empty×4, pawn(b), knight(b)
    #v[ wp .knight, wp .pawn, em, em, em, em, bp .pawn, bp .knight ],
    -- Col 7 (h-file): rook(w), pawn(w), empty×4, pawn(b), rook(b)
    #v[ wp .rook, wp .pawn, em, em, em, em, bp .pawn, bp .rook ]
  ]

def startState : GameState :=
  { board     := startingBoard
    turn      := Colour.white
    castling  := {}    -- all castling rights default to true
    enPassant := none }

-- ==========================================
-- Helper to create positions easily
-- mkPos row col
-- ==========================================

def mkPos (r c : Nat) (hr : r < 8 := by omega) (hc : c < 8 := by omega) : Pos :=
  { row := ⟨r, hr⟩, col := ⟨c, hc⟩ }

def mkMove (r1 c1 r2 c2 : Nat)
    (hr1 : r1 < 8 := by omega) (hc1 : c1 < 8 := by omega)
    (hr2 : r2 < 8 := by omega) (hc2 : c2 < 8 := by omega) : Move :=
  { fromPos := mkPos r1 c1, toPos := mkPos r2 c2 }

-- ==========================================
-- Derive Repr for pretty #eval output
-- ==========================================

deriving instance Repr for Piece
deriving instance Repr for Colour
deriving instance Repr for ColourPiece

-- ==========================================
-- TEST: Board access
-- ==========================================

-- Should print white rook at (0,0)
#eval startingBoard.getSquare (mkPos 0 0)
-- Should print black king at (7,4)
#eval startingBoard.getSquare (mkPos 7 4)
-- Should print none (empty square) at (3,3)
#eval startingBoard.getSquare (mkPos 3 3)

-- ==========================================
-- TEST: Valid pawn moves
-- ==========================================

-- White pawn e2->e3 (row 1, col 4 -> row 2, col 4): should be TRUE
#eval isPseudoLegalMove startState (mkMove 1 4 2 4)

-- White pawn e2->e4 (two-step from start): should be TRUE
#eval isPseudoLegalMove startState (mkMove 1 4 3 4)

-- White pawn e2->e5 (three steps): should be FALSE
#eval isPseudoLegalMove startState (mkMove 1 4 4 4)

-- ==========================================
-- TEST: Invalid moves
-- ==========================================

-- Moving from empty square (3,3): should be FALSE
#eval isPseudoLegalMove startState (mkMove 3 3 4 4)

-- Moving black piece on white's turn (6,4): should be FALSE
#eval isPseudoLegalMove startState (mkMove 6 4 5 4)

-- ==========================================
-- TEST: Knight moves
-- ==========================================

-- White knight b1->c3 (row 0, col 1 -> row 2, col 2): should be TRUE
#eval isPseudoLegalMove startState (mkMove 0 1 2 2)

-- White knight b1->a3 (row 0, col 1 -> row 2, col 0): should be TRUE
#eval isPseudoLegalMove startState (mkMove 0 1 2 0)

-- White knight b1->d2 (row 0, col 1 -> row 1, col 3): should be FALSE (own pawn blocks target)
-- Wait - d2 has a white pawn. Let's check!
#eval isPseudoLegalMove startState (mkMove 0 1 1 3)

-- ==========================================
-- TEST: Blocked pieces at start
-- ==========================================

-- White rook a1->a3 (blocked by own pawn at a2): should be FALSE
#eval isPseudoLegalMove startState (mkMove 0 0 2 0)

-- White bishop c1->e3 (blocked by own pawn at d2): should be FALSE
#eval isPseudoLegalMove startState (mkMove 0 2 2 4)

-- White queen d1->d3 (blocked by own pawn at d2): should be FALSE
#eval isPseudoLegalMove startState (mkMove 0 3 2 3)

-- ==========================================
-- Summary of expected results
-- ==========================================
-- Board access:   some(white rook), some(black king), none
-- Pawn e2-e3:     true
-- Pawn e2-e4:     true
-- Pawn e2-e5:     false
-- Empty square:   false
-- Wrong colour:   false
-- Knight Nb1-c3:  true
-- Knight Nb1-a3:  true
-- Knight Nb1-d2:  false (blocked by own pawn)
-- Rook blocked:   false
-- Bishop blocked: false
-- Queen blocked:  false
