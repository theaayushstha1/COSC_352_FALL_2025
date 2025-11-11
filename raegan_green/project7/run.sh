#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Baltimore Homicide Dashboard - Project 7 ===${NC}"

if ! docker ps > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

IMAGE_NAME="baltimore-dashboard"
TAG="latest"
CONTAINER_NAME="baltimore-dashboard-app"

# Stop and remove existing container
if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
    echo -e "${YELLOW}Stopping existing container...${NC}"
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    docker rm ${CONTAINER_NAME} 2>/dev/null || true
fi

# Build image if not exists
if ! docker image inspect "${IMAGE_NAME}:${TAG}" > /dev/null 2>&1; then
    echo -e "${BLUE}Building Docker image (this may take 2-3 minutes)...${NC}"
    docker build -t "${IMAGE_NAME}:${TAG}" .
    echo -e "${GREEN}Docker image built successfully!${NC}"
else
    echo -e "${GREEN}Docker image found.${NC}"
fi

echo -e "${BLUE}Starting Shiny dashboard...${NC}"

# Run container
docker run -d \
  --name ${CONTAINER_NAME} \
  -p 3838:3838 \
  "${IMAGE_NAME}:${TAG}"

echo -e "\n${GREEN}Dashboard is starting...${NC}"
echo -e "${YELLOW}Waiting for app to initialize (30 seconds)...${NC}"
sleep 30

echo -e "\n${GREEN}✓ Dashboard is ready!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Open your browser and go to:"
echo -e "  ${GREEN}http://localhost:3838${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\nTo stop the dashboard:"
echo -e "  ${YELLOW}docker stop ${CONTAINER_NAME}${NC}"
echo -e "\nTo view logs:"
echo -e "  ${YELLOW}docker logs ${CONTAINER_NAME}${NC}"
echo ""
