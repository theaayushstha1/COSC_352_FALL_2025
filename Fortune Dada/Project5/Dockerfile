FROM eclipse-temurin:21-jdk AS build
RUN apt-get update && apt-get install -y curl gzip && rm -rf /var/lib/apt/lists/*
RUN curl -L -s https://github.com/VirtusLab/scala-cli/releases/download/v1.5.3/scala-cli-x86_64-pc-linux.gz \
  | gunzip > /usr/local/bin/scala-cli && chmod +x /usr/local/bin/scala-cli
WORKDIR /app
COPY src ./src
RUN scala-cli --power package src/Main.scala --assembly -o app.jar

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/app.jar /app/app.jar
ENTRYPOINT ["java","-jar","/app/app.jar"]
