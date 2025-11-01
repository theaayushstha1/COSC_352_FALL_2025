# Use Debian-based Go image
FROM golang:1.21-bullseye

# Set working directory
WORKDIR /app

# Copy Go module files and download dependencies
COPY go.mod go.sum ./
RUN go mod tidy

# Copy source code
COPY . .

# Build fully static binary
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/baltimore-homicides main.go
RUN chmod +x /app/baltimore-homicides

# ENTRYPOINT
ENTRYPOINT ["/app/baltimore-homicides"]
