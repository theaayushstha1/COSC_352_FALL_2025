# Build
docker build -t tm-pingpong .

docker run --rm tm-pingpong "$1"
