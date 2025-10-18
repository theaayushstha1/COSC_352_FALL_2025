# ==========================
# Project 4 — Scala + Docker
# ==========================
FROM openjdk:21-jdk-slim

# Install minimal dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates tar coreutils && \
    rm -rf /var/lib/apt/lists/*

# --- Install Scala 3 ---
ARG SCALA_VER=3.7.3
RUN set -eux; \
    debArch="$(dpkg --print-architecture)"; \
    case "$debArch" in \
      amd64)  scalaArch="x86_64" ;; \
      arm64)  scalaArch="aarch64" ;; \
      *) echo "Unsupported arch: $debArch"; exit 1 ;; \
    esac; \
    base="scala3-${SCALA_VER}-${scalaArch}-pc-linux"; \
    url="https://github.com/scala/scala3/releases/download/${SCALA_VER}/${base}.tar.gz"; \
    echo "Downloading $url"; \
    curl -fL "$url" -o /tmp/scala3.tgz; \
    mkdir -p /usr/local/scala3 && tar -xzf /tmp/scala3.tgz -C /usr/local/scala3 --strip-components=1; \
    rm -f /tmp/scala3.tgz; \
    ln -sf /usr/local/scala3/bin/scala  /usr/local/bin/scala; \
    ln -sf /usr/local/scala3/bin/scalac /usr/local/bin/scalac

# --- Copy and compile project ---
WORKDIR /app
COPY Project4.scala /app/Project4.scala
RUN mkdir -p out && scalac -d out Project4.scala

# --- Run program by default ---
CMD ["java", "-cp", "/usr/local/scala3/lib/*:out", "Project4"]