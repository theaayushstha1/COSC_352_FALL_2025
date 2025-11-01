FROM hseeberger/scala-sbt:11.0.12_1.5.5_2.13.6

WORKDIR /app

COPY src/ /app/src/

RUN mkdir -p /app/output

RUN scalac -d /app/output src/main/scala/BaltimoreHomicideAnalysis.scala

ENTRYPOINT ["scala", "-classpath", "/app/output", "BaltimoreHomicideAnalysis"]