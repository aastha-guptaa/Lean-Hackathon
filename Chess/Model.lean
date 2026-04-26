-- Board is a vector of a vector (fixed length : )

#check Vector

--  inductive types

inductive Piece where
  | pawn
  | rook
  | knight
  | bishop
  | queen
  | king

inductive Colour where
  | black
  | white

structure ColourPiece where
  piece  : Piece
  colour : Colour

abbrev Square := Option ColourPiece
--abbrev Square := Option <| Piece × Colour
-- pawn, white
-- It is either none, or there is a piece, colour type
-- Like Maybe in Haskell
-- problem is well fst, etc

-- board is unfoldable definition.
-- inline macro in c
-- expression
--abbrev Board (r c : Nat) := Vector (Vector Square c) r

abbrev Board := Vector (Vector Square 8) 8
-- take a board, piece and coordinates
-- possible positions move to

abbrev Pos := Fin 8 × Fin 8


structure PiecePos where
  colPiece : ColourPiece
  pos : Pos

-- struct use, kind of like named tuple
-- Take a board, and a function and then apply it?

-- needs to define piece first

-- given a pos, return piecepos

structure SquarePos where
  square : Square
  pos : Pos

def Board.getSquare (board: Board) (pos: Pos) : Square :=
  (board.get pos.1).get pos.2

--vector.set

def Board.setSquare (board: Board) (pos: Pos) (square: Square) : Board :=
  board.set pos.1 ((board.get pos.1).set pos.2 square)

structure Move where
  fromPos : Pos
  toPos   : Pos

/-- Applies a move by moving whatever is at `fromPos` to `toPos`, leaving `fromPos` empty.
    Note: This does not validate if the move is legal according to chess rules. -/
def Board.applyMove (board: Board) (m: Move) : Board :=
  let piece := board.getSquare m.fromPos
  let boardAfterPick := board.setSquare m.fromPos none
  boardAfterPick.setSquare m.toPos piece


