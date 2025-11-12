# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go module files
COPY go.mod ./

# Copy source code
COPY main.go ./

# Build the application
# CGO_ENABLED=0 for static binary
# -a forces rebuild of packages
# -installsuffix cgo for compatibility
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o bmore-homicide .

# Final stage - minimal runtime image
FROM alpine:latest

# Add ca-certificates for HTTPS requests (if needed in future)
RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy only the binary from builder
COPY --from=builder /app/bmore-homicide .

# Default command runs with stdout output
# Can be overridden with: docker run <image> --output=csv
CMD ["./bmore-homicide", "--output=stdout"]