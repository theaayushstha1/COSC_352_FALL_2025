FROM golang:1.21-alpine

WORKDIR /app

# Copy Go source file
COPY main.go .

# Build the Go application
RUN go build -o homicide-analyzer main.go

# Run the application from /app
ENTRYPOINT ["/app/homicide-analyzer"]