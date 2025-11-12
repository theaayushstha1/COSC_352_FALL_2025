# Use official Golang image
FROM golang:1.23

WORKDIR /app

# Copy files
COPY . .

# Build the Go app
RUN go build -o main .

# Run the app
CMD ["./main"]
