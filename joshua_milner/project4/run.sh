#!/bin/bash

# builds docker, if needed, and runs Baltimore Homicide Analysis

set -e  # Exit on any error

# color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# configuration
IMAGE_NAME="baltimore-homicide-analysis"
CONTAINER_NAME="baltimore-analysis-run"

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Baltimore Homicide Analysis System${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker is not installed${NC}"
    echo "Please install Docker from https://docs.docker.com/get-docker/"
    exit 1
fi

# check if Docker daemon is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Docker daemon is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
fi

# check if image exists
echo -e "${YELLOW}Checking for Docker image...${NC}"
if docker images | grep -q "$IMAGE_NAME"; then
    echo -e "${GREEN}Docker image '$IMAGE_NAME' found${NC}"
else
    echo -e "${YELLOW}Docker image '$IMAGE_NAME' not found. Building now...${NC}"
    
    # build the Docker image
    if docker build -t "$IMAGE_NAME" .; then
        echo -e "${GREEN}Docker image built successfully!${NC}"
    else
        echo -e "${RED}ERROR: Failed to build Docker image${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${YELLOW}Running analysis...${NC}"
echo ""

# remove any existing container with the same name
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# run the Docker container
if docker run --name "$CONTAINER_NAME" --rm "$IMAGE_NAME"; then
    echo ""
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}Analysis completed successfully!${NC}"
    echo -e "${GREEN}=====================================${NC}"
else
    echo -e "${RED}ERROR: Analysis failed${NC}"
    exit 1
fi