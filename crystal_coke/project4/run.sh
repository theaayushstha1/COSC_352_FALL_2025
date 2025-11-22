#!/bin/bash
set -e

# Build Docker image
docker build -t baltimore-homicide-analyzer .

# Run container
docker run --rm baltimore-homicide-analyzer

