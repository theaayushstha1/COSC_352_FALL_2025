# Dockerfile for Project 4 (Scala 3 on JDK 21)
FROM openjdk:21-jdk-slim

# Install dependencies needed to fetch Scala and enable HTTPS
RUN apt-get update && apt-get install -y --no-install-recommends wget unzip ca-certificates &&         rm -rf /var/lib/apt/lists/*

# Install Scala 3
ENV SCALA_VERSION=3.5.1
RUN wget -q https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala3-${SCALA_VERSION}.zip &&         unzip -q scala3-${SCALA_VERSION}.zip &&         mv scala3-${SCALA_VERSION} /usr/local/scala &&         rm -f scala3-${SCALA_VERSION}.zip
ENV PATH="/usr/local/scala/bin:${PATH}"

# App code
WORKDIR /app
COPY Project4.scala /app/Project4.scala

# Compile
RUN scalac Project4.scala

# Default command runs the Scala program
CMD ["scala", "Project4"]
