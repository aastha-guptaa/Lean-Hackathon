import json
import os
import sys
from typing import List, Literal

from pydantic import BaseModel, Field

OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-5")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-pro")
ANTHROPIC_MODEL = os.getenv("ANTHROPIC_MODEL", "claude-sonnet-4-20250514")


class ChessMove(BaseModel):
    """Represents a single chess move with piece, color, and positions."""

    piece: Literal["king", "queen", "rook", "bishop", "knight", "pawn"]
    color: Literal["white", "black"]
    initial_position: str = Field(
        description="The square the piece starts on (e.g., 'e1')."
    )
    final_position: str = Field(
        description="The square the piece moves to (e.g., 'g1')."
    )


class CheckmateSolution(BaseModel):
    """The sequence of moves leading to checkmate."""

    moves: List[ChessMove]


def get_prompt(fen: str) -> str:
    return (
        f"Analyze this chess board position given in FEN notation: {fen}\n"
        "Provide the sequence of forced moves for a checkmate. "
        "Strictly adhere to these formatting rules:\n"
        "1. DO NOT use algebraic notation (e.g., avoid 'Nf3', 'Qh5+').\n"
        "2. Provide every move as a 4-tuple: (piece name, color of piece, initial square, final square).\n"
        "3. A square on the board is a string of length 2, with an alphabet from 'a' to 'h' for file and a number from '1' to '8' for rank (e.g., 'e4').\n"
        "4. Identify the 'color' for every move ('white' or 'black').\n"
        "5. Output the moves in the correct sequential order.\n"
        "6. Use ONLY these piece names: 'king', 'queen', 'rook', 'bishop', 'knight', 'pawn'.\n"
        "7. For CASTLING: Represent the move ONLY as the king moving two squares to the left or right (e.g., 'e1' to 'g1' for white kingside, or 'e8' to 'c8' for black queenside). Do not include a separate rook move.\n"
        "8. Output ONLY valid JSON with top-level key 'moves'."
    )


def parse_solution_from_json_text(text: str) -> CheckmateSolution:
    # Providers sometimes wrap JSON in markdown fences; strip them if present.
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.strip("`")
        if cleaned.startswith("json"):
            cleaned = cleaned[4:].strip()

    data = json.loads(cleaned)
    return CheckmateSolution.model_validate(data)


def solve_with_openai(fen: str) -> CheckmateSolution:
    from openai import OpenAI

    client = OpenAI()
    completion = client.beta.chat.completions.parse(
        model=OPENAI_MODEL,
        messages=[
            {
                "role": "system",
                "content": "You are a Grandmaster chess engine specializing in tactical checkmate puzzles. You output move sequences that lead to checkmate in a specific structured JSON format.",
            },
            {"role": "user", "content": get_prompt(fen)},
        ],
        response_format=CheckmateSolution,
    )
    parsed = completion.choices[0].message.parsed
    if parsed is None:
        raise RuntimeError("OpenAI returned no parsed response.")
    return parsed


def solve_with_gemini(fen: str) -> CheckmateSolution:
    from google import genai

    client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
    resp = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=get_prompt(fen),
        config={"response_mime_type": "application/json"},
    )
    text = (resp.text or "").strip()
    if not text:
        raise RuntimeError("Gemini returned empty response text.")
    return parse_solution_from_json_text(text)


def solve_with_anthropic(fen: str) -> CheckmateSolution:
    import anthropic

    client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
    msg = client.messages.create(
        model=ANTHROPIC_MODEL,
        max_tokens=2000,
        system="You are a Grandmaster chess engine specializing in tactical checkmate puzzles. Return only JSON.",
        messages=[{"role": "user", "content": get_prompt(fen)}],
    )

    text_parts: List[str] = []
    for block in msg.content:
        if getattr(block, "type", None) == "text":
            text_parts.append(block.text)
    text = "\n".join(text_parts).strip()

    if not text:
        raise RuntimeError("Anthropic returned no text response.")
    return parse_solution_from_json_text(text)


def solve_chess_puzzle(fen: str) -> CheckmateSolution:
    backend = os.getenv("LLM_BACKEND", "openai").strip().lower()
    if backend == "openai":
        return solve_with_openai(fen)
    if backend == "gemini":
        return solve_with_gemini(fen)
    if backend == "anthropic":
        return solve_with_anthropic(fen)
    raise ValueError("Unsupported LLM_BACKEND. Use one of: openai, gemini, anthropic")


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python script.py '<FEN_STRING>'")
        sys.exit(1)

    fen = sys.argv[1]
    backend = os.getenv("LLM_BACKEND", "openai").strip().lower()

    try:
        solution = solve_chess_puzzle(fen)
        print(solution.model_dump_json(indent=2))
    except Exception as e:
        error_output = {
            "status": "error",
            "backend": backend,
            "message": str(e),
        }
        print(json.dumps(error_output, indent=2))
        sys.exit(1)


if __name__ == "__main__":
    main()
