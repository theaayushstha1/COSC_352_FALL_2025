# Dockerfile
FROM openjdk:17-slim

WORKDIR /app

# Install minimal tools to download Scala
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Scala 2.13.12 (native toolchain only)
RUN wget -q https://downloads.lightbend.com/scala/2.13.12/scala-2.13.12.tgz && \
    tar -xzf scala-2.13.12.tgz && \
    mv scala-2.13.12 /usr/share/scala && \
    rm scala-2.13.12.tgz

ENV PATH="/usr/share/scala/bin:${PATH}"
ENV SCALA_HOME="/usr/share/scala"

# Copy source and compile
COPY Baltimore.scala /app/Baltimore.scala
RUN scalac /app/Baltimore.scala

# Run
CMD ["scala", "-classpath", "/app", "Baltimore"]
