#!/bin/bash
# =========================================
# Baltimore Homicide Statistics Runner
# =========================================

IMAGE_NAME="baltimore-homicide-analysis"
CONTAINER_NAME="baltimore-homicide-container"

# Capture all arguments (like --output=json)
ARGS="$@"

# Step 1: Build image if not exists
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "🔧 Building Docker image..."
  docker build -t "$IMAGE_NAME" .
else
  echo "✅ Docker image already exists."
fi

# Step 2: Run container, forward arguments, mount current dir
echo "🚀 Running Baltimore Homicide Analysis..."
docker run --rm \
  --name "$CONTAINER_NAME" \
  -v "$(pwd):/app" \
  "$IMAGE_NAME" \
  $ARGS

echo "✅ Analysis complete."
