FROM golang:latest AS builder

WORKDIR /app
COPY go.* ./
RUN go mod download

COPY . /app

RUN go mod tidy
RUN go build -o /main

ENTRYPOINT [ "/main" ]
