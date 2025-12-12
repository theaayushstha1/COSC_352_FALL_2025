# Turing Machine Simulator for \(a^n b^n c^n\)

This project implements a Turing Machine (TM) simulator in Python that recognizes the language \(a^n b^n c^n\) where \(n \geq 1\). This is a classic example of a context-sensitive language, requiring a TM with marking and backtracking logic, making it more complex than simulators for regular or context-free languages.

The program is CLI-based, takes an input string, simulates the TM step-by-step, prints the state trace, and evaluates whether the input is accepted (pass) or rejected (fail). It is dockerized for easy deployment.

## Approach
- **Turing Machine Design**: The TM uses a single tape and marks symbols ('a' → 'X', 'b' → 'Y', 'c' → 'Z') to count and match the number of 'a's, 'b's, and 'c's. It repeatedly marks one from each group and backtracks. If counts match and all are marked without extras or shortages, it accepts; otherwise, rejects.
  - States: q0 (start), q1 (after backtrack), q2 (find/mark b), q3 (find/mark c), q4 (backtrack left), q5 (accept).
  - Tape extends infinitely left/right using a list.
  - Transitions handle skipping marked symbols and detecting mismatches (via no transition → reject).
  - Complexity: 6 states, ~20 transitions, handles non-context-free language with O(n^2) time (multiple passes over tape).
- **Simulator Implementation**: Adapted from standard Python TM templates, with added tracing (state, tape, head) and max steps limit.
- **Evaluation**: Accepts if reaches q5; rejects if no transition or max steps exceeded. Prints trace for each step.
- **Dockerization**: Uses a slim Python image for portability.
- **Leveraging Generative AI**: This project was developed with assistance from Grok (built by xAI), a generative AI model. Grok was queried for language recommendations (Python selected for expressiveness), searched for TM examples and code snippets (e.g., via web_search and browse_page tools), and generated the initial code structure, transitions, and documentation. I refined the transitions for completeness and added tracing/Docker based on Grok's suggestions. This accelerated implementation while ensuring accuracy.

## Requirements
- Docker installed on your machine.
- Git (for cloning from GitHub).

## Run Instructions
1. **Clone the Repository**: