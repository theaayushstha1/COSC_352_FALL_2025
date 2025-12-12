# Multi-stage build for smaller final image
FROM golang:1.21-alpine AS builder

# Set working directory
WORKDIR /app

# Copy source code
COPY main.go .

# Build the Go application
RUN go build -o bmore-analysis main.go

# Final stage - minimal runtime image
FROM alpine:latest

WORKDIR /app

# Copy the binary from builder
COPY --from=builder /app/bmore-analysis .

# Set entrypoint
ENTRYPOINT ["/app/bmore-analysis"]
