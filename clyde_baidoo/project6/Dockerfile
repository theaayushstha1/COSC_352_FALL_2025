FROM golang:1.22-alpine

WORKDIR /app
COPY . /app

# Use ENTRYPOINT instead of CMD to allow arguments
ENTRYPOINT ["go", "run", "main.go"]