# Multi-stage build for optimized image size
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go mod files first for better caching
COPY go.mod go.sum* ./

# Download dependencies (if go.sum exists)
RUN go mod download || true

# Copy source code
COPY main.go ./

# Build the application
# CGO_ENABLED=0 for static binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o baltimore-analysis .

# Final stage - minimal runtime image
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /app/baltimore-analysis .

# Create output directory
RUN mkdir -p /output

ENTRYPOINT ["./baltimore-analysis"]
