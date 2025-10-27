FROM eclipse-temurin:17-jdk

RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates gnupg && \
    curl -fsSL https://www.scala-lang.org/files/archive/scala-2.13.12.deb -o /tmp/scala.deb || \
    (curl -fsSL https://downloads.lightbend.com/scala/2.13.12/scala-2.13.12.deb -o /tmp/scala.deb) && \
    apt-get install -y /tmp/scala.deb && \
    rm -rf /var/lib/apt/lists/* /tmp/scala.deb

WORKDIR /app

COPY src ./src

RUN mkdir -p /app/out && scalac -encoding UTF-8 -d /app/out src/Main.scala


ENTRYPOINT ["scala", "-cp", "/app/out", "Main"]
CMD []
