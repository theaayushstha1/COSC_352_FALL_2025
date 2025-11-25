#!/bin/bash

echo "========================================"
echo "Baltimore Homicides Dashboard"
echo "========================================"
echo ""

IMAGE_NAME="baltimore-homicides-dashboard"
CONTAINER_NAME="baltimore-homicides-app"
PORT=3838

# Parse command line arguments
REBUILD=false
STOP_ONLY=false

for arg in "$@"; do
    case $arg in
        --rebuild)
            REBUILD=true
            shift
            ;;
        --stop)
            STOP_ONLY=true
            shift
            ;;
        --port=*)
            PORT="${arg#*=}"
            shift
            ;;
    esac
done

# Function to stop and remove existing container
cleanup_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Stopping existing container..."
        docker stop "$CONTAINER_NAME" 2>/dev/null
        echo "Removing existing container..."
        docker rm "$CONTAINER_NAME" 2>/dev/null
    fi
}

# If --stop flag is used, just stop and exit
if [ "$STOP_ONLY" = true ]; then
    echo "Stopping Baltimore Homicides Dashboard..."
    cleanup_container
    echo "✓ Dashboard stopped!"
    exit 0
fi

# Clean up any existing container
cleanup_container

# Check if image exists or if rebuild is requested
if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1 || [ "$REBUILD" = true ]; then
    echo "Building Docker image..."
    echo "This may take several minutes on first build..."
    echo ""
    
    docker build -t "$IMAGE_NAME" .
    
    if [ $? -ne 0 ]; then
        echo ""
        echo "✗ Docker build failed!"
        exit 1
    fi
    
    echo ""
    echo "✓ Docker image built successfully!"
else
    echo "✓ Docker image already exists (use --rebuild to rebuild)"
fi

echo ""
echo "Starting dashboard container..."
echo "Port: $PORT"
echo ""

# Run the container
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "$PORT:3838" \
    "$IMAGE_NAME"

if [ $? -ne 0 ]; then
    echo ""
    echo "✗ Failed to start container!"
    exit 1
fi

# Wait a moment for the server to start
echo "Waiting for Shiny Server to start..."
sleep 3

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo ""
    echo "========================================"
    echo "✓ Dashboard is running!"
    echo "========================================"
    echo ""
    echo "Access the dashboard at:"
    echo "  http://localhost:$PORT/baltimore-homicides/"
    echo ""
    echo "To view logs:"
    echo "  docker logs -f $CONTAINER_NAME"
    echo ""
    echo "To stop the dashboard:"
    echo "  ./run.sh --stop"
    echo "  or: docker stop $CONTAINER_NAME"
    echo ""
else
    echo ""
    echo "✗ Container failed to start!"
    echo "Check logs with: docker logs $CONTAINER_NAME"
    exit 1
fi
echo "========================================"