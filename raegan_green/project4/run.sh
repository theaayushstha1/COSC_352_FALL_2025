#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Baltimore Homicide Analysis - Project 4 ===${NC}"

if ! docker ps > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

IMAGE_NAME="homicide-analysis"
TAG="latest"

if ! docker image inspect "${IMAGE_NAME}:${TAG}" > /dev/null 2>&1; then
    echo -e "${BLUE}Building Docker image...${NC}"
    docker build -t "${IMAGE_NAME}:${TAG}" .
    echo -e "${GREEN}Docker image built successfully!${NC}"
else
    echo -e "${GREEN}Docker image found. Running analysis...${NC}"
fi

echo -e "${BLUE}Executing analysis...${NC}\n"
docker run --rm "${IMAGE_NAME}:${TAG}"
echo -e "\n${GREEN}Analysis complete!${NC}"