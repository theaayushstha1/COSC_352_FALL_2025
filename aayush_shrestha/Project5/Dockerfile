FROM openjdk:17-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Scala
RUN wget https://downloads.lightbend.com/scala/2.13.12/scala-2.13.12.tgz && \
    tar -xzf scala-2.13.12.tgz && \
    mv scala-2.13.12 /usr/share/scala && \
    rm scala-2.13.12.tgz

ENV PATH="/usr/share/scala/bin:${PATH}"
ENV SCALA_HOME="/usr/share/scala"

# Copy source file
COPY BaltimoreHomicideAnalysis.scala .

# Compile
RUN scalac BaltimoreHomicideAnalysis.scala

# Change CMD to ENTRYPOINT to accept arguments
ENTRYPOINT ["scala", "-classpath", ".", "BaltimoreHomicideAnalysis"]
