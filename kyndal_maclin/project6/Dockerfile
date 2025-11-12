# ===============================
# Baltimore Homicide Analysis
# Go + Docker
# ===============================

FROM golang:1.24.9-alpine

# Install dependencies
RUN apk add --no-cache git

# Set working directory
WORKDIR /app

# Copy go mod files first for better caching
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download && go mod verify

# Copy source code
COPY main.go ./

# Build the application
RUN go build -o baltimore-analysis .

# Create output directory and set entrypoint
RUN mkdir -p /app/output
WORKDIR /app/output

# Run the application
ENTRYPOINT ["/app/baltimore-analysis"]