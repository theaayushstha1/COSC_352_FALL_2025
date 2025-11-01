# ==========================
# Project 6 — Golang + Docker
# ==========================
FROM golang:1.23

# --- Copy and build project ---
WORKDIR /app
COPY main.go /app/main.go
RUN go build -o project6 main.go

# --- Run program by default ---
ENTRYPOINT ["./project6"]