#!/bin/bash

echo "Running Baltimore Homicide Analysis for 2024..."
docker build -t homicide-analysis .
docker run --rm homicide-analysis
