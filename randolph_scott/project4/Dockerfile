FROM openjdk:11-jdk-slim

RUN apt-get update && apt-get install -y wget ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Project4.scala /app/Project4.scala

# install scala (uses Debian packaged scala as fallback)
RUN set -eux; \
    apt-get update; \
    apt-get install -y scala || true; \
    rm -rf /var/lib/apt/lists/*

# compile
RUN scalac Project4.scala

CMD ["scala", "Project4"]
