#!/bin/bash
# =========================================
# Baltimore Homicide Statistics Runner (Go)
# =========================================

set -e  # Exit on any error

IMAGE_NAME="baltimore-homicide-go"
CONTAINER_NAME="baltimore-homicide-container"

# Capture all arguments
ARGS="$@"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔧 Building Docker image...${NC}"
docker build -t "$IMAGE_NAME" .

echo -e "${YELLOW}🚀 Running Baltimore Homicide Analysis...${NC}"
docker run --rm \
  --name "$CONTAINER_NAME" \
  -v "$(pwd):/app/output" \
  "$IMAGE_NAME" \
  $ARGS

echo -e "${GREEN}✅ Analysis complete.${NC}"

# List generated files
echo -e "\n${YELLOW}📁 Generated files:${NC}"
if ls baltimore_output.* 1> /dev/null 2>&1; then
    ls -la baltimore_output.*
else
    echo "No output files generated (console output only)"
fi