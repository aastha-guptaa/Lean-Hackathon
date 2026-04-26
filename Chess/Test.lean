import Chess.Model
import Chess.Display
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
  -- Board is ROW-major: outer index = row (0..7), inner index = col (a=0..h=7)
  #v[
    -- Row 0: white back rank
    #v[ wp .rook, wp .knight, wp .bishop, wp .queen, wp .king, wp .bishop, wp .knight, wp .rook ],
    -- Row 1: white pawns
    #v[ wp .pawn, wp .pawn, wp .pawn, wp .pawn, wp .pawn, wp .pawn, wp .pawn, wp .pawn ],
    -- Row 2-5: empty
    #v[ em, em, em, em, em, em, em, em ],
    #v[ em, em, em, em, em, em, em, em ],
    #v[ em, em, em, em, em, em, em, em ],
    #v[ em, em, em, em, em, em, em, em ],
    -- Row 6: black pawns
    #v[ bp .pawn, bp .pawn, bp .pawn, bp .pawn, bp .pawn, bp .pawn, bp .pawn, bp .pawn ],
    -- Row 7: black back rank
    #v[ bp .rook, bp .knight, bp .bishop, bp .queen, bp .king, bp .bishop, bp .knight, bp .rook ]
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
-- TEST: Board.canMove
-- ==========================================

-- Valid white pawn move: e2 -> e3
#eval startingBoard.canMove
  { colPiece := { piece := Piece.pawn, colour := Colour.white }, pos := { row := 1, col := 4 } }
  { row := 2, col := 4 }  -- should be true

-- Valid white pawn move: e2 -> e4 (double step from start)
#eval startingBoard.canMove
  { colPiece := { piece := Piece.pawn, colour := Colour.white }, pos := { row := 1, col := 4 } }
  { row := 3, col := 4 }  -- should be true

-- Invalid white pawn move: e2 -> e5 (too far)
#eval startingBoard.canMove
  { colPiece := { piece := Piece.pawn, colour := Colour.white }, pos := { row := 1, col := 4 } }
  { row := 4, col := 4 }  -- should be false

-- Valid knight move: b1 -> c3
#eval startingBoard.canMove
  { colPiece := { piece := Piece.knight, colour := Colour.white }, pos := { row := 0, col := 1 } }
  { row := 2, col := 2 }  -- should be true

-- Invalid knight move: b1 -> d2 (blocked by own pawn)
#eval startingBoard.canMove
  { colPiece := { piece := Piece.knight, colour := Colour.white }, pos := { row := 0, col := 1 } }
  { row := 1, col := 3 }  -- should be false

-- Move from empty square (3,3)
#eval startingBoard.canMove
  { colPiece := { piece := Piece.pawn, colour := Colour.white }, pos := { row := 3, col := 3 } }
  { row := 4, col := 4 }  -- should be false (no piece at source)

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

#eval startingBoard
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
