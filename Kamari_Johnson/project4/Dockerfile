FROM openjdk:11

RUN apt-get update && apt-get install -y scala

WORKDIR /app

COPY src/Main.scala .
COPY data/baltimore_homicides.csv ./data/

RUN scalac Main.scala

CMD ["scala", "-cp", ".", "Main"]