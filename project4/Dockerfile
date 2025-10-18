FROM openjdk:11
RUN apt-get update && apt-get install -y scala
WORKDIR /app
COPY . /app
RUN scalac src/Main.scala -d Main.jar
CMD ["scala", "-classpath", "Main.jar", "Main"]
