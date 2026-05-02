# Chess

Create a Python venv with the `pydantic` and `openai` modules installed.

Ensure that your OpenAI API Key is stored in the `OPENAI_API_KEY` env variable.

Activate the Python venv, and navigate to the root of the repo.

Build the Lean project.

```bash
lake build
```

Run the following to get the LLM to solve the checkmate puzzle:

```bash
lake exe chess "<FEN>"
```

where you replace \<FEN\> with the FEN notation of the checkmate puzzle.

Example:

```bash
lake exe chess "1rb5/4r3/3p1npb/3kp1P1/1P3P1P/5nR1/2Q1BK2/bN4NR w - - 3 61"
```

Output:

```
Output from LLM: {
  "moves": [
    {
      "piece": "queen",
      "color": "white",
      "initial_position": "c2",
      "final_position": "c4"
    }
  ]
}

=================================
Puzzle Successfully Solved!
The board positions to checkmate:


Valid: true
Turn: black
Move Number: 62
□♖♗□□□□□
□□□□♖□□□
□□□♙□♘♙♗
□□□♔♙□♟□
□♟♛□□♟□♟
□□□□□♘♜□
□□□□♝♚□□
♗♞□□□□♞♜
```

You can set the model you want to use at the start of `script.py`. Use `gpt-5` onwards for better results.