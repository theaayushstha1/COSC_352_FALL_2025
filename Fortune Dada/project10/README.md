# Turing Machine Simulator (Project 10)

This project is a full Turing Machine simulator implemented in Python and dockerized for easy execution.



## Features

- Reads machine configuration from JSON
- Executes transitions step-by-step
- Prints full state trace for every step
- Evaluates input as ACCEPT or REJECT
- Dockerized — runs on any machine


## Language Simulated

This Turing Machine recognizes the language:

    L = { a^n b^n | n ≥ 1 }

Examples accepted:
- `ab`
- `aabb`
- `aaabbb`

Examples rejected:
- `abb`
- `aab`
- `ba`

---

