#!/usr/bin/env bash
set -euo pipefail

# build
go build -o project5-go main.go

# run with sample input
./project5-go -input sample_input.json -workers 4
chmod +x run.sh
./run.sh
