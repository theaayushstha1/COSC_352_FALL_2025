#!/bin/bash

OUTPUT_FORMAT=""

# Parse argument
for arg in "$@"
do
  case $arg in
    --output=*)
      OUTPUT_FORMAT="${arg#*=}"
      shift
      ;;
    *)
      ;;
  esac
done

# Build the program
go build -o baltimore-homicides main.go

# Run program
if [ -z "$OUTPUT_FORMAT" ]; then
    ./baltimore-homicides
else
    ./baltimore-homicides --output=$OUTPUT_FORMAT
fi
