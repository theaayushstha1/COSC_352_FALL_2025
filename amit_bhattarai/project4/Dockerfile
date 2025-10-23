FROM openjdk:17-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends scala ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY src ./src

RUN scalac -d out src/Main.scala

CMD ["scala", "-cp", "out", "Main"]
