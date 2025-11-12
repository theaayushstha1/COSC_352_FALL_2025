# Use official Golang image as base
FROM golang:1.21-alpine

# Set working directory
WORKDIR /app

# Copy source code
COPY BaltimoreHomicideAnalysis.go .

# Build the Go binary
RUN go build -o baltimore-analysis BaltimoreHomicideAnalysis.go

# Default command runs without arguments (stdout)
CMD ["./baltimore-analysis"]