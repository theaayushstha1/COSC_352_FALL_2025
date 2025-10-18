# Project 4 — Scala + Docker (Baltimore Homicide data)

This repo contains a Scala 3 program that fetches homicide rows from the Baltimore City
homicide list on **chamspage.blogspot.com** (2025 page) and answers two questions:

1. **How many homicides occurred in each month of 2025?**
2. **What is the closure rate for incidents with and without surveillance cameras in 2025?**

> Uses only the Scala/Java standard library (no 3rd‑party libs). It compiles and runs inside Docker.

## Files
- `Project4.scala` — Scala source (object `Project4`).
- `Dockerfile` — Builds a JDK 21 + Scala 3 image, compiles, and sets `scala Project4` as the default CMD.
- `run.sh` — Rebuilds the Docker image and runs the program (no parameters required).

## How to run (locally or GitHub Codespaces)
```bash
# From the project root (same folder as Dockerfile/run.sh/Project4.scala)
chmod +x run.sh
./run.sh
```

The script will:
- Build the image `project4:latest` using the Dockerfile.
- Run the container, which executes the compiled Scala program.

## Notes for GitHub Codespaces
- Codespaces generally supports Docker out of the box; if you see any permission errors,
  try restarting the Codespace or ensure your user is in the `docker` group.
- The container needs outbound internet to fetch the blog page. This is enabled by default.

## Implementation details
- We fetch HTML using a custom User‑Agent to avoid potential 403 responses.
- Rows are parsed heuristically: we look for lines that start with a 3‑digit counter followed by `MM/DD/YY`.
- We infer camera mentions by the regex `\b\d+\s*cameras?\b` and closure by the keyword `closed` (case‑insensitive).

## Grading checklist
- [x] Git submission
- [x] Dockerized
- [x] Program runs via `run.sh` without parameters
- [x] Standard library only (Scala/Java)
- [x] Two original, useful questions with printed answers
