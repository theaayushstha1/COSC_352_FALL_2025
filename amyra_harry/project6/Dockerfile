FROM golang:1.21-alpine AS builder

# Set working directory
WORKDIR /app

# Copy the Go source file
COPY BaltimoreHomicideAnalysis.go .

# Initialize Go module (if you don't have go.mod)
RUN go mod init baltimore-homicide-analysis || true

# Build the Go program (use the actual filename)
RUN go build -o baltimore-analysis BaltimoreHomicideAnalysis.go

# Use a smaller base image for the final container
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy the compiled binary from builder
COPY --from=builder /app/baltimore-analysis .

# Use ENTRYPOINT to properly handle arguments
ENTRYPOINT ["./baltimore-analysis"]