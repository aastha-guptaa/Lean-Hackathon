import Chess.Model

def Piece.toIcon (piece: Piece) (colour: Colour) : String :=
  match piece, colour with
  | .king,   .white => "♚"
  | .queen,  .white => "♛"
  | .rook,   .white => "♜"
  | .bishop, .white => "♝"
  | .knight, .white => "♞"
  | .pawn,   .white => "♟"
  | .king,   .black => "♔"
  | .queen,  .black => "♕"
  | .rook,   .black => "♖"
  | .bishop, .black => "♗"
  | .knight, .black => "♘"
  | .pawn,   .black => "♙"

def Square.toIcon (square: Square) : String :=
  match square with
  | none => "□"
  | some cp => cp.piece.toIcon cp.colour

instance : Repr Square where
  reprPrec square _ := square.toIcon

#check Vector.foldl

def vecToString {n : Nat} (v : Vector Square n) : String :=
  v.foldl (fun s sq => s ++ sq.toIcon) ""

instance : Repr Board where
  reprPrec board _ :=
    board.foldl (fun s row => s ++ vecToString row ++ "\n") ""

instance : Repr GameState where
  reprPrec gs n := reprPrec gs.board n


