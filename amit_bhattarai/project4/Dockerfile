FROM openjdk:17-slim

# install curl and ca-certificates for HTTPS
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# install Scala manually (latest stable 2.13.x)
RUN curl -fsSL https://downloads.lightbend.com/scala/2.13.14/scala-2.13.14.tgz -o scala.tgz && \
    tar -xzf scala.tgz -C /usr/local && \
    ln -s /usr/local/scala-2.13.14 /usr/local/scala && \
    ln -s /usr/local/scala/bin/* /usr/local/bin/ && \
    rm scala.tgz

WORKDIR /app
COPY src ./src

RUN mkdir -p out && scalac -d out src/Main.scala

CMD ["scala", "-cp", "out", "Main"]
