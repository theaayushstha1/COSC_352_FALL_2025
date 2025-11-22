FROM golang:1.22

WORKDIR /app

COPY cmd/analyzer/main.go .

RUN CGO_ENABLED=0 GOOS=linux go build -o /analyzer main.go

CMD ["/analyzer"]