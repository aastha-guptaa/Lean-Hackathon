-- Board is a vector of a vector (fixed length : )

#check Vector

--  inductive types

/-- The pieces on a chessboard. -/
inductive Piece where
  | pawn
  | rook
  | knight
  | bishop
  | queen
  | king
deriving BEq

/-- The colour of a piece. -/
inductive Colour where
  | black
  | white
deriving BEq, DecidableEq

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

--abbrev Pos := Fin 8 × Fin 8

structure Pos where
  row : Fin 8
  col : Fin 8
deriving BEq

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
  (board.get pos.row).get pos.col

--vector.se

def Board.setSquare (board: Board) (pos: Pos) (square: Square) : Board :=
  board.set pos.row ((board.get pos.row).set pos.col square)

structure Move where
  fromPos : Pos
  toPos   : Pos

/-- Applies a move by moving whatever is at `fromPos` to `toPos`, leaving `fromPos` empty.
    Note: This does not validate if the move is legal according to chess rules. -/
def Board.applyMove (board: Board) (m: Move) : Board :=
  let piece := board.getSquare m.fromPos
  let boardAfterPick := board.setSquare m.fromPos none
  boardAfterPick.setSquare m.toPos piece

-- ==========================================
-- Game State (needed for castling & en passant)
-- ==========================================

/-- Tracks whether castling is still allowed for each side. -/
structure CastlingRights where
  whiteKingSide  : Bool := true
  whiteQueenSide : Bool := true
  blackKingSide  : Bool := true
  blackQueenSide : Bool := true

/-- The complete state needed to validate a move. -/
structure GameState where
  board     : Board
  turn      : Colour
  castling  : CastlingRights
  enPassant : Option (Fin 8)  -- column of a pawn that just moved two steps

-- ==========================================
-- Helper functions
-- ==========================================

/-- Signed distance between two Fin 8 values. -/
def posDist (a b : Fin 8) : Int :=
  (a.val : Int) - (b.val : Int)

/-- Try to create a Fin 8 from an Int, returning none if out of bounds. -/
def intToFin8 (n : Int) : Option (Fin 8) :=
  if h : 0 ≤ n ∧ n < 8 then
    some ⟨n.toNat, by omega⟩
  else
    none

/-- Ensures a piece isn't landing on a square occupied by its own colour. -/
def isValidTarget (board : Board) (colour : Colour) (toPos : Pos) : Bool :=
  match board.getSquare toPos with
  | none    => true
  | some cp => cp.colour != colour

/-- Check if all squares strictly between fromPos and toPos are empty.
    Assumes the move is along a straight line or diagonal. -/
def isPathClear (board : Board) (fromPos toPos : Pos) : Bool :=
  let dc := posDist toPos.col fromPos.col
  let dr := posDist toPos.row fromPos.row
  let stepC : Int := if dc > 0 then 1 else if dc < 0 then -1 else 0
  let stepR : Int := if dr > 0 then 1 else if dr < 0 then -1 else 0
  let steps := max dc.natAbs dr.natAbs
  if steps ≤ 1 then true
  else
    let rec loop (i : Nat) (fuel : Nat) : Bool :=
      match fuel with
      | 0 => true
      | fuel' + 1 =>
        if i ≥ steps then true
        else
          let c := (fromPos.col.val : Int) + stepC * i
          let r := (fromPos.row.val : Int) + stepR * i
          match intToFin8 c, intToFin8 r with
          | some cf, some rf =>
            match board.getSquare { col := cf, row := rf } with
            | some _ => false   -- blocked!
            | none   => loop (i + 1) fuel'
          | _, _ => false       -- out of bounds
    loop 1 7  -- at most 7 intermediate squares on an 8×8 board

-- ==========================================
-- Piece-specific move rules
-- ==========================================

def isValidKnightMove (fromPos toPos : Pos) : Bool :=
  let dc := (posDist toPos.col fromPos.col).natAbs
  let dr := (posDist toPos.row fromPos.row).natAbs
  (dc == 2 && dr == 1) || (dc == 1 && dr == 2)

def isValidRookMove (board : Board) (fromPos toPos : Pos) : Bool :=
  let dc := posDist toPos.col fromPos.col
  let dr := posDist toPos.row fromPos.row
  (dc == 0 || dr == 0) && isPathClear board fromPos toPos

def isValidBishopMove (board : Board) (fromPos toPos : Pos) : Bool :=
  let dc := (posDist toPos.col fromPos.col).natAbs
  let dr := (posDist toPos.row fromPos.row).natAbs
  dc == dr && dc != 0 && isPathClear board fromPos toPos

def isValidQueenMove (board : Board) (fromPos toPos : Pos) : Bool :=
  isValidRookMove board fromPos toPos || isValidBishopMove board fromPos toPos


def isValidKingMove (board : Board) (fromPos toPos : Pos) : Bool :=
  let dc := posDist toPos.col fromPos.col
  let dr := posDist toPos.row fromPos.row
  -- Standard one-square move
  dc.natAbs ≤ 1 && dr.natAbs ≤ 1 && (dc != 0 || dr != 0)


/-
else if dc.natAbs == 2 && dr == 0 then
    let baseRow : Fin 8 := match state.turn with | Colour.white => ⟨0, by omega⟩ | Colour.black => ⟨7, by omega⟩
    if fromPos.col.val == 4 && fromPos.row == baseRow then
      if dc == 2 then  -- kingside
        let allowed := match state.turn with
          | Colour.white => state.castling.whiteKingSide
          | Colour.black => state.castling.blackKingSide
        allowed && isPathClear state.board fromPos { col := ⟨7, by omega⟩, row := baseRow }
      else  -- dc == -2, queenside
        let allowed := match state.turn with
          | Colour.white => state.castling.whiteQueenSide
          | Colour.black => state.castling.blackQueenSide
        allowed && isPathClear state.board fromPos { col := ⟨0, by omega⟩, row := baseRow }
    else false
  else false
-/

def isValidPawnMove (state : GameState) (fromPos toPos : Pos) : Bool :=
  let dc := posDist toPos.col fromPos.col
  let dr := posDist toPos.row fromPos.row
  let dir : Int := match state.turn with | Colour.white => 1 | Colour.black => -1
  let startRow : Nat := match state.turn with | Colour.white => 1 | Colour.black => 6
  let target := state.board.getSquare toPos
  -- Forward moves (no capture)
  if dc == 0 then
    if dr == dir then
      target.isNone  -- single step forward
    else if dr == 2 * dir && fromPos.row.val == startRow then
      target.isNone && isPathClear state.board fromPos toPos  -- double step from start
    else false
  -- Diagonal captures
  else if dc.natAbs == 1 && dr == dir then
    match target with
    | some cp => cp.colour != state.turn  -- standard capture
    | none =>
      -- En passant
      match state.enPassant with
      | some epCol =>
        let epRow : Nat := match state.turn with | Colour.white => 4 | Colour.black => 3
        toPos.col == epCol && fromPos.row.val == epRow
      | none => false
  else false

-- ==========================================
-- Main move validator
-- ==========================================

/-- Checks if a move is pseudo-legal: correct piece geometry, path is clear,
    not capturing own piece. Does NOT check if the king is left in check. -/
def isPseudoLegalMove (state : GameState) (m : Move) : Bool :=
  match state.board.getSquare m.fromPos with
  | none => false
  | some cp =>
    -- Must move your own colour
    if cp.colour != state.turn then false
    -- Cannot stay in place
    else if m.fromPos == m.toPos then false
    -- Cannot capture your own piece
    else if !(isValidTarget state.board state.turn m.toPos) then false
    -- Piece-specific rule
    else match cp.piece with
      | Piece.pawn   => isValidPawnMove state m.fromPos m.toPos
      | Piece.knight => isValidKnightMove m.fromPos m.toPos
      | Piece.rook   => isValidRookMove state.board m.fromPos m.toPos
      | Piece.bishop => isValidBishopMove state.board m.fromPos m.toPos
      | Piece.queen  => isValidQueenMove state.board m.fromPos m.toPos
      | Piece.king   => isValidKingMove state.board m.fromPos m.toPos

/-- Checks if a piece can move from one position to another.
    Uses pseudo-legal validation (correct piece movement, path clear, not capturing own piece).
    Does NOT check if the move leaves the king in check. -/
def Board.canMove (board: Board) (piecePos: PiecePos) (destPos: Pos) : Bool :=
  let state : GameState := {
    board := board,
    turn := piecePos.colPiece.colour,
    castling := {},
    enPassant := none
  }
  let move : Move := { fromPos := piecePos.pos, toPos := destPos }
  isPseudoLegalMove state move
