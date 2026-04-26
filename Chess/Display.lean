import Chess.Model

def Piece.toIcon (piece: Piece) (colour: Colour) : String :=
  match piece, colour with
  | .king,   .white => "♔"
  | .queen,  .white => "♕"
  | .rook,   .white => "♖"
  | .bishop, .white => "♗"
  | .knight, .white => "♘"
  | .pawn,   .white => "♙"
  | .king,   .black => "♚"
  | .queen,  .black => "♛"
  | .rook,   .black => "♜"
  | .bishop, .black => "♝"
  | .knight, .black => "♞"
  | .pawn,   .black => "♟"

def Square.toIcon (square: Square) : String :=
  match square with
  | none => "□"
  | some cp => cp.piece.toIcon cp.colour

instance : Repr Square where
  reprPrec square _ := square.toIcon
