 FROM golang:1.23-bookworm


WORKDIR /app

COPY main.go ./

RUN go mod init app && go build -o app .

ENTRYPOINT ["/app/app"]
CMD []
