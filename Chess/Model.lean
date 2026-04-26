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

structure ColourPiecePos where
  colourPiece : ColourPiece
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
  colourPiecePos : ColourPiecePos
  toPos : Pos

/-- Applies a move by moving whatever is at `fromPos` to `toPos`, leaving `fromPos` empty.
    Note: This does not validate if the move is legal according to chess rules. -/
def Board.forceMove (board : Board) (move : Move) : Board :=
  let piece := move.colourPiecePos.colourPiece
  let boardWithoutPiece := board.setSquare move.colourPiecePos.pos none
  boardWithoutPiece.setSquare move.toPos piece

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

def getDists (fromPos toPos : Pos) : Int × Int :=
  let dr := posDist toPos.row fromPos.row
  let dc := posDist toPos.col fromPos.col
  (dr, dc)

def isStraight (fromPos toPos : Pos) : Bool :=
  let (dr, dc) := getDists fromPos toPos
  (dc == 0 || dr == 0)

def isDiagonal (fromPos toPos : Pos) : Bool :=
  let (dr, dc) := getDists fromPos toPos
  (dc == dr && dc != 0)

def isStraightOrDiagonal (fromPos toPos : Pos) : Bool :=
  (isStraight fromPos toPos) || (isDiagonal fromPos toPos)

/-- Check if all squares strictly between fromPos and toPos are empty.
    The square at toPos can be non-empty (a capture move). -/
def isPathClear (board : Board) (fromPos toPos : Pos) : Bool :=
  if !(isStraightOrDiagonal fromPos toPos) then
    false
  else
    let (dr, dc) := getDists fromPos toPos
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

def isValidKingMove (fromPos toPos : Pos) : Bool :=
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

def validPawnMoveHelper (move : Int × Int) (isUp : Bool) : Bool :=
  let dir := if isUp then
    (1,2)
  else
    (-1,-2)
  (move == (dir.2,0)) || (move == (dir.1,0)) || (move == (dir.1,dir.1))

def isValidPawnMove (board : Board) (colour : Colour) (fromPos toPos : Pos) : Bool :=
  let move := getDists fromPos toPos
  let (dr, dc) := move
  match colour with
  | .white =>
    if validPawnMoveHelper move true then
      sorry
    else
      false
  | .black =>
    if validPawnMoveHelper move false then
      sorry
    else
      false

-- ==========================================
-- Main move validator
-- ==========================================

/-- Checks if a move is pseudo-legal: correct piece geometry, path is clear,
    not capturing own piece. Does NOT check if the king is left in check. -/
def isPseudoLegalMove (state : GameState) (move : Move) : Bool :=
  match state.board.getSquare move.colourPiecePos.pos with
  | none => false
  | some cp =>
    -- Must move your own colour
    if cp.colour != state.turn then false
    -- Cannot stay in place
    else if move.colourPiecePos.pos == move.toPos then false
    -- Cannot capture your own piece
    else if !(isValidTarget state.board state.turn move.toPos) then false
    -- Piece-specific rule
    else match cp.piece with
      | Piece.pawn   => isValidPawnMove state.board move.colourPiecePos.colourPiece.colour move.colourPiecePos.pos move.toPos
      | Piece.knight => isValidKnightMove move.colourPiecePos.pos move.toPos
      | Piece.rook   => isValidRookMove state.board move.colourPiecePos.pos move.toPos
      | Piece.bishop => isValidBishopMove state.board move.colourPiecePos.pos move.toPos
      | Piece.queen  => isValidQueenMove state.board move.colourPiecePos.pos move.toPos
      | Piece.king   => isValidKingMove move.colourPiecePos.pos move.toPos

/-- Checks if a piece can move from one position to another.
    Uses pseudo-legal validation (correct piece movement, path clear, not capturing own piece).
    Does NOT check if the move leaves the king in check. -/
def Board.canMove (board: Board) (colourPiecePos: ColourPiecePos) (destPos: Pos) : Bool :=
  let state : GameState := {
    board := board,
    turn := colourPiecePos.colourPiece.colour,
    castling := {},
    enPassant := none
  }
  let move : Move := { colourPiecePos := colourPiecePos, toPos := destPos }
  isPseudoLegalMove state move
