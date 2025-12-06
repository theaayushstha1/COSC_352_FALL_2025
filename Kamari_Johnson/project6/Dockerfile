# Use official Golang image
FROM golang:latest

# Set working directory
WORKDIR /app

# Copy everything into the container
COPY . .

# Build the Go binary
RUN go build -o project6

# Run the binary
CMD ["./project6"]