FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod ./

COPY main.go ./

RUN go build -o baltimore-analysis main.go

FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /app

COPY --from=builder /app/baltimore-analysis .

ENTRYPOINT ["./baltimore-analysis"]