FROM openjdk:11-jdk-slim

ENV SCALA_VERSION=2.13.12
RUN apt-get update && \
    apt-get install -y wget && \
    wget -q https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz && \
    tar -xzf scala-${SCALA_VERSION}.tgz && \
    mv scala-${SCALA_VERSION} /usr/share/scala && \
    ln -s /usr/share/scala/bin/* /usr/bin/ && \
    rm scala-${SCALA_VERSION}.tgz && \
    apt-get clean

WORKDIR /app

COPY src/main/scala/BaltimoreHomicideAnalysis.scala /app/

RUN scalac BaltimoreHomicideAnalysis.scala

RUN mkdir -p /app/output

ENTRYPOINT ["sh", "-c", "scala -classpath /app BaltimoreHomicideAnalysis.scala \"$@\"", "--"]

CMD ["stdout"]