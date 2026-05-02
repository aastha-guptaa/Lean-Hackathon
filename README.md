# Verified LLM Chess: Mate-in-N Solver

## Origin
This project was built during the **LeanLang for Verified
Autonomy Hackathon** (April 17–18 + online through May 1, 2026) at the **Indian Institute of Science (IISc),
Bangalore**.
Sponsored by **[Emergence AI](https://www.emergence.ai)**
Organized by **[Emergence India Labs]
(https://east.emergence.ai)** in collaboration with
**IISc Bangalore**.

## Problem Objective
The goal of this project is to create a formally verified bridge between Large Language Models (LLMs) and a mathematical proof engine (Lean 4). Specifically, it targets **Chess Mate-in-N puzzles**, where an LLM suggests a sequence of moves to achieve checkmate, and Lean 4 rigorously verifies that:
1. Every move in the sequence is physically legal according to the rules of chess.
2. The final state is a mathematically sound checkmate.

## Setup
Create a Python venv with the `pydantic` and `openai` modules installed.
Ensure that your OpenAI API Key is stored in the `OPENAI_API_KEY` environment variable.
Activate the Python venv, and navigate to the root of the repo.

## Running the Tool
1. Build the Lean project:
```bash
lake build
```

2. Run the solver with a FEN string:
```bash
lake exe chess "<FEN>"
```
Example:
```bash
lake exe chess "1rb5/4r3/3p1npb/3kp1P1/1P3P1P/5nR1/2Q1BK2/bN4NR w - - 3 61"
```

## Suggested Puzzles
You can find several Mate-in-N puzzles in FEN notation to test here:
*   [Mate in 2 Puzzles](https://wtharvey.com/m8n2.txt)
*   [Mate in 3 Puzzles](https://wtharvey.com/m8n3.txt)
*   [Mate in 4 Puzzles](https://wtharvey.com/m8n4.txt)

## Acknowledgments
This project was made possible by:
- **Emergence AI** — Hackathon sponsor
- **Emergence India Labs** — Event organizer and
research direction
- **Indian Institute of Science (IISc), Bangalore** —
Academic partner, hackathon co-design, tutorials,
and mentorship

## Links
- [Hackathon Page](https://east.emergence.ai/hackathon-april2026.html)
- [Emergence India Labs](https://east.emergence.ai)
- [Emergence AI](https://www.emergence.ai)