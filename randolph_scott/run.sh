#!/bin/bash

# Default output is stdout
OUTPUT_FORMAT="stdout"

# Parse the flag
for arg in "$@"
do
  case $arg in
    --output=*)
      OUTPUT_FORMAT="${arg#*=}"
      shift
      ;;
  esac
done

# Run the Scala program through sbt
sbt "runMain com.example.Project5Main $OUTPUT_FORMAT"

