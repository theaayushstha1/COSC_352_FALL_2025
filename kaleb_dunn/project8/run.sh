#!/bin/bash

IMAGE_NAME="project8"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Baltimore Homicide Analysis - Clojure                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
  echo "📦 Building Docker image (first time: 3-5 minutes)..."
  docker build -t $IMAGE_NAME .
  
  if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
  fi
  
  echo "✓ Build complete!"
  echo ""
fi

echo "🚀 Running analysis..."
echo ""
docker run --rm $IMAGE_NAME
echo ""
echo "✓ Analysis complete!"
