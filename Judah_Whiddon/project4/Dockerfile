FROM eclipse-temurin:17-jdk

# Install Scala 2.13.12
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates gnupg && \
    curl -fsSL https://www.scala-lang.org/files/archive/scala-2.13.12.deb -o /tmp/scala.deb || \
    (curl -fsSL https://downloads.lightbend.com/scala/2.13.12/scala-2.13.12.deb -o /tmp/scala.deb) && \
    apt-get install -y /tmp/scala.deb && \
    rm -rf /var/lib/apt/lists/* /tmp/scala.deb

WORKDIR /app
COPY src ./src
RUN mkdir -p /app/out && scalac -d /app/out src/Main.scala

CMD ["scala", "-cp", "/app/out", "Main"]