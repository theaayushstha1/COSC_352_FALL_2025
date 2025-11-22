#!/bin/bash

# Build the Docker image
docker build -t homicide-analysis-go .

# Check if an output format was specified
if [ "$1" == "--output=csv" ]; then
    docker run --rm -v "$(pwd)":/app/output homicide-analysis-go sh -c "./homicide-analysis --output=csv && cp output.csv /app/output/"
elif [ "$1" == "--output=json" ]; then
    docker run --rm -v "$(pwd)":/app/output homicide-analysis-go sh -c "./homicide-analysis --output=json && cp output.json /app/output/"
else
    docker run --rm homicide-analysis-go
fi