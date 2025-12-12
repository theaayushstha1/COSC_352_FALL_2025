# Multi-stage build for Go
# Stage 1: Build the Go binary
FROM golang:1.21-alpine AS builder

WORKDIR /build

# Copy Go source code
COPY main.go .

# Build the binary
# CGO_ENABLED=0 creates a static binary (no external dependencies)
# -ldflags="-w -s" strips debug info to make binary smaller
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o homicide-analysis main.go

# Stage 2: Create minimal runtime image
FROM alpine:latest

WORKDIR /app

# Create output directory
RUN mkdir -p /app/output

# Copy only the compiled binary from builder stage
COPY --from=builder /build/homicide-analysis /app/

# Run the program
CMD ["/app/homicide-analysis"]
