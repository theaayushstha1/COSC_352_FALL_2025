# Builder stage
FROM golang:1.21 as builder

WORKDIR /app

# Cache dependencies
COPY go.mod ./
RUN go mod download

# Copy source
COPY . .

# Build statically-linked binary (CGO disabled)
ENV CGO_ENABLED=0
RUN go build -ldflags="-s -w" -o /project5-go ./main.go

# Final stage: very small image
FROM scratch
COPY --from=builder /project5-go /project5-go

ENTRYPOINT ["/project5-go"]
