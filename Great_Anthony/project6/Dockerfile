# Use official Golang image as builder
FROM golang:1.21-alpine AS builder

# Set working directory
WORKDIR /app

# Copy go files
COPY main.go .

# Initialize Go module
RUN go mod init homicide-analysis

# Build the application
RUN go build -o homicide-analysis main.go

# Use minimal alpine image for final container
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates wget

# Set working directory
WORKDIR /app

# Copy the binary from builder
COPY --from=builder /app/homicide-analysis .

# Create data directory
RUN mkdir -p data

# Download the dataset
RUN wget -O data/homicide-data.csv https://raw.githubusercontent.com/washingtonpost/data-homicides/master/homicide-data.csv

# Make the binary executable
RUN chmod +x homicide-analysis

# Set the entrypoint
ENTRYPOINT ["./homicide-analysis"]

# Default to stdout output
CMD ["stdout"]
