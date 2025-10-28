#!/bin/bash

# build.sh - Compile Scala Crime Data Analysis Application

set -e

echo "================================"
echo "Building Crime Data Analysis Tool"
echo "================================"
echo ""

# Create necessary directories
echo "Creating directories..."
mkdir -p target/scala-2.13/classes
mkdir -p data
mkdir -p output

# Compile the Scala application
echo "Compiling Scala source files..."
scalac -d target/scala-2.13/classes src/main/scala/CrimeDataApp.scala

echo ""
echo "================================"
echo "Build Complete!"
echo "================================"
echo ""
echo "You can now run the application with:"
echo "  ./run.sh                  # Default stdout output"
echo "  ./run.sh --output=csv     # CSV output"
echo "  ./run.sh --output=json    # JSON output"
