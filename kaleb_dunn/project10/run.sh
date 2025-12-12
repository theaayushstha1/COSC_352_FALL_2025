#!/bin/bash

IMAGE_NAME="turing-machine"
CONTAINER_NAME="turing-sim"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        Turing Machine Simulator - Docker Runner             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if image exists
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
  echo "📦 Building Docker image..."
  docker build -t $IMAGE_NAME .
  
  if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
  fi
  
  echo "✓ Build complete!"
  echo ""
fi

# Run container interactively
echo "🚀 Starting Turing Machine Simulator..."
echo ""
docker run -it --rm --name $CONTAINER_NAME $IMAGE_NAME