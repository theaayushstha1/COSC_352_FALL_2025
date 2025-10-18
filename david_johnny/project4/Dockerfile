FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

# Install curl and bash for downloading Scala
RUN apk add --no-cache bash curl

# Install Scala manually
RUN curl -fLo /usr/local/bin/coursier https://git.io/coursier-cli && \
    chmod +x /usr/local/bin/coursier && \
    coursier setup --yes --jvm 17

COPY Main.scala .
RUN scalac Main.scala
CMD ["scala", "Main"]
