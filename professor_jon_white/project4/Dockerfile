FROM sbtscala/scala-sbt:eclipse-temurin-jammy-17.0.9_9_1.9.7_2.13.12

WORKDIR /app

COPY build.sbt .
COPY HelloWorld.scala .

RUN sbt compile

CMD ["sbt", "run"]
