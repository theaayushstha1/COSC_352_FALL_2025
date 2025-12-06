# Project 10 — Turing Machine Simulator

This simulator runs a Turing Machine defined in a JSON file.
It prints a full execution trace and halts with PASS or FAIL.
A step limit prevents infinite loops.

---

## Run Locally

python3 tm.py <input>

Example:
python3 tm.py 101

Use a custom TM definition:
python3 tm.py 110 --tm tm_definition.json

---

## Docker

### Build
docker build -t project10_tm .

### Run
docker run --rm project10_tm 101

Or with a custom TM file inside the container:
docker run --rm project10_tm 110 --tm tm_definition.json

---
