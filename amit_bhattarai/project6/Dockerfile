# ---- Build stage ----
FROM golang:1.22-alpine AS build
WORKDIR /app

# Install CA certificates for HTTPS requests
RUN apk update && apk add --no-cache ca-certificates && update-ca-certificates

COPY go.mod ./
RUN go mod download

COPY cmd ./cmd
ENV CGO_ENABLED=0
RUN go build -o /app/app ./cmd/app

# ---- Runtime stage ----
FROM alpine:3.20
WORKDIR /app

# Copy CA certs from builder
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /app/app /app/app
VOLUME ["/app/out"]
ENTRYPOINT ["/app/app"]
