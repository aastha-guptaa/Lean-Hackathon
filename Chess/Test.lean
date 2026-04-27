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

#eval startingBoard

def startState : GameState :=
  { board     := startingBoard
    turn      := Colour.white
    castling  := {}    -- all castling rights default to true
    enPassant := none
    valid := true
    moveNum := 0
    history := [] }

#eval startState

-- ==========================================
-- Position & Move helpers
-- ==========================================

def mkPos (r c : Nat) (hr : r < 8 := by omega) (hc : c < 8 := by omega) : Pos :=
  { row := ⟨r, hr⟩, col := ⟨c, hc⟩ }

/-- Create a Move given piece, colour, from (row,col), to (row,col). -/
def mkMove (piece : Piece) (colour : Colour) (r1 c1 r2 c2 : Nat)
    (hr1 : r1 < 8 := by omega) (hc1 : c1 < 8 := by omega)
    (hr2 : r2 < 8 := by omega) (hc2 : c2 < 8 := by omega) : Move :=
  { colourPiecePos := {
      colourPiece := { piece := piece, colour := colour }
      pos := mkPos r1 c1 }
    toPos := mkPos r2 c2 }

-- ==========================================
-- Derive Repr for pretty #eval output
-- ==========================================

deriving instance Repr for Piece
deriving instance Repr for Colour
deriving instance Repr for ColourPiece
deriving instance Repr for Pos
deriving instance Repr for CastlingRights

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
-- TEST: isPseudoLegalMove
-- ==========================================

-- White pawn e2→e3: should be TRUE
#eval isPseudoLegalMove startState (mkMove .pawn .white 1 4 2 4)

-- White pawn e2→e4 (two-step): should be TRUE
#eval isPseudoLegalMove startState (mkMove .pawn .white 1 4 3 4)

-- White pawn e2→e5 (three steps): should be FALSE
#eval isPseudoLegalMove startState (mkMove .pawn .white 1 4 4 4)

-- Moving from empty square (3,3): should be FALSE
#eval isPseudoLegalMove startState (mkMove .pawn .white 3 3 4 3)

-- Moving black piece on white's turn: should be FALSE
#eval isPseudoLegalMove startState (mkMove .pawn .black 6 4 5 4)

-- White knight b1→c3: should be TRUE
#eval isPseudoLegalMove startState (mkMove .knight .white 0 1 2 2)

-- White knight b1→a3: should be TRUE
#eval isPseudoLegalMove startState (mkMove .knight .white 0 1 2 0)

-- White knight b1→d2 (blocked by own pawn): should be FALSE
#eval isPseudoLegalMove startState (mkMove .knight .white 0 1 1 3)

-- White rook a1→a3 (blocked): should be FALSE
#eval isPseudoLegalMove startState (mkMove .rook .white 0 0 2 0)

-- White bishop c1→e3 (blocked): should be FALSE
#eval isPseudoLegalMove startState (mkMove .bishop .white 0 2 2 4)

-- White queen d1→d3 (blocked): should be FALSE
#eval isPseudoLegalMove startState (mkMove .queen .white 0 3 2 3)

-- ==========================================
-- TEST: GameState.makeMove
-- ==========================================

-- Move 1: White plays e2→e4 (pawn double push)
def move1 := mkMove .pawn .white 1 4 3 4
def state1 := startState.makeMove move1

-- #eval state1.isSome                                               -- true
-- #eval do let s ← state1; return s.board.getSquare (mkPos 1 4)    -- none (e2 empty)
-- #eval do let s ← state1; return s.board.getSquare (mkPos 3 4)    -- some (pawn, white)
-- #eval do let s ← state1; return s.turn                            -- Colour.black
-- #eval do let s ← state1; return s.enPassant                       -- some 4

-- -- Move 2: Black plays d7→d5 (pawn double push)
-- def move2 := mkMove .pawn .black 6 3 4 3
-- def state2 := do let s ← state1; s.makeMove move2

-- #eval state2.isSome                                               -- true
-- #eval do let s ← state2; return s.board.getSquare (mkPos 6 3)    -- none (d7 empty)
-- #eval do let s ← state2; return s.board.getSquare (mkPos 4 3)    -- some (pawn, black)
-- #eval do let s ← state2; return s.turn                            -- Colour.white
-- #eval do let s ← state2; return s.enPassant                       -- some 3

-- -- Move 3: White plays Nf3 (knight g1→f3)
-- def move3 := mkMove .knight .white 0 6 2 5
-- def state3 := do let s ← state2; s.makeMove move3

-- #eval state3.isSome                                               -- true
-- #eval do let s ← state3; return s.board.getSquare (mkPos 2 5)    -- some (knight, white)
-- #eval do let s ← state3; return s.board.getSquare (mkPos 0 6)    -- none (g1 empty)
-- #eval do let s ← state3; return s.enPassant                       -- none (en passant cleared)

-- -- Illegal: White tries to move again (it's black's turn)
-- def illegalMove := mkMove .pawn .white 1 3 2 3
-- def stateIllegal := do let s ← state3; s.makeMove illegalMove
-- #eval stateIllegal.isSome                                         -- false

-- ==========================================
-- Summary of expected results
-- ==========================================
-- Board access:        some(white rook), some(black king), none
-- Pawn e2-e3:          true
-- Pawn e2-e4:          true
-- Pawn e2-e5:          false
-- Empty square move:   false
-- Wrong colour:        false
-- Knight Nb1-c3:       true
-- Knight Nb1-a3:       true
-- Knight Nb1-d2:       false
-- Rook blocked:        false
-- Bishop blocked:      false
-- Queen blocked:       false
-- makeMove e2-e4:      isSome=true, e2=none, e4=white pawn, turn=black, ep=some 4
-- makeMove d7-d5:      isSome=true, d7=none, d5=black pawn, turn=white, ep=some 3
-- makeMove Nf3:        isSome=true, f3=knight, g1=none, ep=none
-- illegal double-move: isSome=false
