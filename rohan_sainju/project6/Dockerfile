FROM golang:1.21-alpine

WORKDIR /app

COPY homicides.csv .
COPY main.go .

RUN go build -o homicide-analysis main.go

CMD ["./homicide-analysis"]