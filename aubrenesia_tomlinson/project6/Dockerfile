# build stage
FROM golang:1.23-alpine AS builder

# set directory
WORKDIR /app

# copy file
COPY . .

# build static binary
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# runtime stage
FROM alpine:latest

# add certificates for reqs
RUN apk --no-cache add ca-certificates

WORKDIR /app
COPY --from=builder /app/main .
COPY run.sh .

# default ouput
ENTRYPOINT ["./run.sh"]
CMD []
