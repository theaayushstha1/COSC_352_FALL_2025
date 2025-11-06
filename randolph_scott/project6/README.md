# Project 5 — Golang Port (project5-go)

This repository is a Go port template of Project 5. It demonstrates idiomatic Go patterns: CLI flags, JSON I/O, worker pool concurrency, error handling, unit testing, and Docker multi-stage build.

## Files
- `main.go` - CLI entrypoint. Reads JSON array of items and processes them concurrently.
- `processor/processor.go` - core logic to process items.
- `processor/processor_test.go` - unit tests.
- `sample_input.json` - example input.
- `Dockerfile` - multi-stage Dockerfile using official golang image.
- `run.sh` - local build/run helper (make executable).
- `.dockerignore` / `.gitignore`

## Quick start (local)
1. Ensure Go 1.21+ installed.
2. Build:
   ```bash
   go build -o project5-go main.go
