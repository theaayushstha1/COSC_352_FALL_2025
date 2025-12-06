#!/usr/bin/env bash
# run_pdfsearch.sh
#
# Wrapper to mimic:
#   ./pdfsearch document.pdf "query string" N
#
# Usage:
#   ./run_pdfsearch.sh morgan2030.pdf "query string" 3

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <pdf_path> <query string> <N>" >&2
  exit 1
fi

PDF="$1"
QUERY="$2"
N="$3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TSV="${SCRIPT_DIR}/passages.tsv"

# 1. Extract passages using Python (PDF → TSV)
python3 "${SCRIPT_DIR}/pdf_extract.py" "${PDF}" "${TSV}"

# 2. Run Mojo search over TSV
mojo run "${SCRIPT_DIR}/pdfsearch.mojo" "${TSV}" "${QUERY}" "${N}"
