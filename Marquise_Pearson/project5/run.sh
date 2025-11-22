#!/usr/bin/env bash
set -euo pipefail

OUTPUT_FORMAT=""
OTHER_ARGS=()

# Parse --output flag (e.g., --output=csv or --output json)
for arg in "$@"; do
  case "$arg" in
    --output=*)
      OUTPUT_FORMAT="${arg#*=}"
      ;;
    --output)
      shift || true
      OUTPUT_FORMAT="${1:-}"
      ;;
    *)
      OTHER_ARGS+=("$arg")
      ;;
  esac
done

# --- Use scala-cli (preferred for Codespaces) ---
if command -v scala-cli >/dev/null 2>&1; then
  ARGS=("${OTHER_ARGS[@]}")
  if [[ -n "$OUTPUT_FORMAT" ]]; then
    ARGS+=( "--output" "$OUTPUT_FORMAT" )
  fi
  echo "Running with scala-cli..."
  exec scala-cli run src/main -- "${ARGS[@]}"
fi

# --- Fallback: classic scalac/scala ---
echo "scala-cli not found; using classic scalac/scala..."
mkdir -p out
scalac -d out src/main/
