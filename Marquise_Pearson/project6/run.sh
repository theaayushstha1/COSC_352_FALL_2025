#!/usr/bin/env bash
set -euo pipefail
IMG=project6-go:latest

docker build -t "$IMG" .

INPUT="${1:-/app/data/homicides.csv}"
YEAR="${2:-2025}"
Q="${3:-q1}"
OUT="${4:-json}"

exec docker run --rm -it \
  -v "$PWD/data:/app/data" \
  "$IMG" \
  --input "$INPUT" --year "$YEAR" --question "$Q" --out "$OUT"
