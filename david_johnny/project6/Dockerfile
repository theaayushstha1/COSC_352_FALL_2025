# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /build

# Copy go source
COPY main.go .

# Build the application
RUN go build -o homicide-parser main.go

# Runtime stage
FROM alpine:latest

WORKDIR /app

# Copy the binary from builder
COPY --from=builder /build/homicide-parser .

# Run the program (can be overridden with parameters)
CMD ["./homicide-parser"]