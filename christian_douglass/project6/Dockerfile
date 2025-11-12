FROM golang:1.21-bullseye
WORKDIR /app

# Cache go modules
COPY go.mod .
RUN go env -w GOPROXY="https://proxy.golang.org,direct"
RUN go mod download

# Copy sources
COPY . .

# Build binary
RUN CGO_ENABLED=0 go build -o /homicide ./

# Run the binary by default
ENTRYPOINT ["/homicide"]
