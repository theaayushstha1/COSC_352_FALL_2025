FROM openjdk:11-jdk-slim AS builder
WORKDIR /app

RUN apt-get update && \
    apt-get install -y curl && \
    curl -L -o sbt.deb https://repo.scala-sbt.org/scalasbt/debian/sbt-1.9.7.deb && \
    dpkg -i sbt.deb && \
    rm sbt.deb && \
    apt-get clean

COPY build.sbt ./
RUN mkdir -p project src/main/scala
COPY project ./project
COPY src ./src

RUN sbt clean assembly || sbt clean package

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=builder /app/target/scala-2.13/*.jar /app/app.jar
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
