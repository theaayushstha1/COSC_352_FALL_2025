#!/bin/bash

echo "Running Baltimore Homicide Analysis for 2024..."

# Get absolute Windows-style path
HOST_PATH=$(pwd | sed 's|/c/|C:/|' | sed 's|/|\\|g')

docker build -t homicide-analysis -f Dockerfile.clean .

docker run --rm -v "$HOST_PATH:/app" homicide-analysis bash -c "sbt \"run -- $*\""
