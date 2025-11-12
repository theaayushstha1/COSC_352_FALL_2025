$IMAGE_NAME = "project4-scala-homicide:latest"
$DIRNAME = $PSScriptRoot

# Check if Docker image exists; if not, build it
try {
    docker image inspect $IMAGE_NAME | Out-Null
    Write-Host "Docker image $IMAGE_NAME found. Skipping build."
}
catch {
    Write-Host "Docker image $IMAGE_NAME not found. Building..."
    docker build -t $IMAGE_NAME $DIRNAME
}

# Run the container
Write-Host "Running Scala program inside Docker..."
docker run --rm $IMAGE_NAME