FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go module file
COPY go.mod .

# Copy source code
COPY the_article.go .

# Install the 'file' utility so the build-stage verification command (file ...) works
RUN apk add --no-cache file

# List files to verify they're copied
RUN echo "Files in /app:" && ls -la

# Build static binary with CGO disabled
RUN CGO_ENABLED=0 GOOS=linux go build -o baltimore-analysis the_article.go

# Verify the binary was created
RUN echo "Build complete. Binary info:" && ls -la baltimore-analysis && file baltimore-analysis

# Final stage - smaller runtime image
FROM alpine:latest

# Install Python and dependencies
RUN apk --no-cache add python3 py3-pip ca-certificates

WORKDIR /app

# Copy Go binary from builder
# Copy Go binary from builder to a location outside of /app so a host
# bind-mount of the project directory won't hide the binary at runtime.
COPY --from=builder /app/baltimore-analysis /usr/local/bin/baltimore-analysis

# Verify binary was copied and make executable
RUN echo "Files in final stage (app dir):" && ls -la /app/ || true && \
    echo "Binary location:" && ls -la /usr/local/bin/baltimore-analysis && \
    chmod +x /usr/local/bin/baltimore-analysis

# Copy Python requirements and install
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt --break-system-packages || true

# Copy Python script
COPY get_mine.py .

# Entry point with absolute path outside the mounted /app
ENTRYPOINT ["/usr/local/bin/baltimore-analysis"]

# Default output format
CMD ["-output=stdout"]