FROM openjdk:17-slim

# install scala (on Debian-based image)
RUN apt-get update && apt-get install -y curl gnupg && \
    curl -fsSL https://www.scala-lang.org/files/archive/scala-2.13.13.deb -o scala.deb && \
    apt-get install -y ./scala.deb && rm scala.deb

WORKDIR /app
COPY . /app

CMD ["scala", "src/main.scala"]

