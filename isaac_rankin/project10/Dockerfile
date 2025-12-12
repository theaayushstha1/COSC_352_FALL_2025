# Build Stage
FROM gcc:11 as builder
WORKDIR /app
COPY turing_machine.cpp .
RUN g++ turing_machine.cpp -o tm-pingpong -std=c++17 -O2

# Run Stage
FROM debian:stable-slim
WORKDIR /bin
COPY --from=builder /app/tm-pingpong .
ENTRYPOINT ["./tm-pingpong"]