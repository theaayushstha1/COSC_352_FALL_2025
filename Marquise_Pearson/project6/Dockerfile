FROM golang:1.23-alpine AS build
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /out/project6 ./cmd/project6

FROM scratch
WORKDIR /app
COPY --from=build /out/project6 /usr/local/bin/project6
COPY --from=build /app/data /app/data
ENTRYPOINT ["/usr/local/bin/project6"]
