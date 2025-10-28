#!/bin/bash
# =========================================
# Baltimore Homicide Statistics Runner
# Builds and runs Scala analysis in Docker
# =========================================

IMAGE_NAME="baltimore-homicide-analysis"
CONTAINER_NAME="baltimore-homicide-container"

# Step 1: Check if Docker image exists
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "🔧 Building Docker image..."
  docker build -t "$IMAGE_NAME" .
else
  echo "✅ Docker image already exists."
fi

# Step 2: Run the container
echo "🚀 Running Baltimore Homicide Analysis..."
docker run --name "$CONTAINER_NAME" --rm "$IMAGE_NAME"

# (The --rm flag ensures the container is automatically cleaned up after exit)

echo "✅ Analysis complete."

