#!/bin/bash

# Default output format
OUTPUT_FORMAT="stdout"

# Parse optional --output flag
for arg in "$@"; do
  case $arg in
    --output=*)
      OUTPUT_FORMAT="${arg#*=}"
      shift
      ;;
  esac
done

# Compile and run the Scala program
scalac p5main.scala
scala p5Main "$OUTPUT_FORMAT"
