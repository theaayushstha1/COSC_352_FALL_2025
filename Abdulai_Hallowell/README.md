# Project 10 — Turing Machine Simulator

Project 10 is a small Turing Machine simulator written in Python and packaged in Docker.

**Short overview**
- A Turing Machine (TM) is a formal model of computation consisting of a tape, a head that reads/writes, and a finite control (states and transitions).
- This simulator models the tape, transitions, and control, and runs step-by-step, printing a full trace.

This project includes a non-trivial sample machine that decides the language {0^n1^n | n >= 0} (equal number of 0s followed by 1s).

**Repository layout (all under `project10/`)**
- `main.py` — CLI entrypoint.
- `turing_machine/core.py` — `TuringMachine` and `Tape` classes and simulator engine.
- `turing_machine/machines.py` — predefined machines (currently `equal-zeros-ones`).
- `Dockerfile` — builds runnable container.
- `requirements.txt` — (empty; no external deps).
- `README.md` — this file.

**How the sample machine works (0^n1^n)**
- The machine marks a leading `0` with `X`, then scans right to find the first unmarked `1` and marks it with `Y`.
- It returns to the left to find another unmarked `0` and repeats.
- If all symbols are properly paired, it halts in the accept state; otherwise it rejects.

Design details
- States, tape alphabet, blank symbol, and transitions are modeled directly as Python structures.
- Transitions are a dict keyed by `(state, symbol)` with values `(next_state, write_symbol, move)`.
- `Tape` is implemented as a dynamic list which grows if the head moves off either end.
- The simulator loop:
  1. Read current symbol
  2. Look up `delta(state, symbol)`
  3. Write symbol, move head, change state
  4. Record a trace entry and repeat until halting or max steps

Setup & Requirements
- Language: Python 3.12 (image uses `python:3.12-slim`)
- The professor can run everything via Docker — no setup is required on host aside from Docker.

How to build the Docker image
-----------------------------
Run these commands in a terminal:

```bash
cd project10
docker build -t project10-turing .
```

How to run the program
----------------------

- Run non-interactive (CLI) example — accepted input:

```bash
docker run --rm -it project10-turing --machine equal-zeros-ones --input 0011
```

Expected (example) output (abbreviated):

Step 0: state=q_start, head=0, tape=[0] 0 0 1 1 _
  action: write 'X', move R, next_state=q_find_1
Step 1: state=q_find_1, head=1, tape= X 0 1 1 _
  action: write '0', move R, next_state=q_find_1
... (more steps)

RESULT: ACCEPT (PASS)
Reason: Halted in accepting state q_accept after N steps.

- Run non-interactive (CLI) example — rejecting input:

```bash
docker run --rm -it project10-turing --machine equal-zeros-ones --input 010
```

Expected output (abbreviated):

Step 0: state=q_start, head=0, tape=[0] 1 0 _
  action: write 'X', move R, next_state=q_find_1
... (more steps)

RESULT: REJECT (FAIL)
Reason: No transition defined for (state=..., symbol=...) or halted in rejecting state.

Interactive mode
----------------
If you omit `--input`, the container will start in interactive mode and prompt for inputs:

```bash
docker run --rm -it project10-turing
```

Then follow prompts to enter input strings or leave blank to quit.

Example runs (local CLI)
------------------------
If running outside Docker (on a machine with Python 3 installed):

```bash
python main.py --machine equal-zeros-ones --input 0011
python main.py --machine equal-zeros-ones --input 010
python main.py --machine equal-zeros-ones
# (then enter strings interactively)
```

Error handling
--------------
- The program validates that input characters belong to the machine's input alphabet and reports a clear error like:

  Error: Input contains invalid symbol '2'. Valid symbols are ['0', '1']

Use of Generative AI
--------------------
- I used a generative AI assistant to:
  - Plan the project structure and module boundaries.
  - Draft the initial implementation of the `TuringMachine`, `Tape`, and CLI.
  - Create a draft `Dockerfile` and `README.md` content and sample outputs.
- I reviewed, ran, and tested the code locally and adjusted logic and formatting; the final work represents my understanding and validation.

Future improvements
-------------------
- Add support to load machine definitions from JSON/YAML files.
- Improve tape visualization (show more context, compress blank regions).
- Add automated tests and CI to validate behavior on multiple inputs.
