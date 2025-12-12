FROM openjdk:11

RUN apt-get update && \
    apt-get install -y scala

WORKDIR /app

COPY p5main.scala .
COPY run.sh .

RUN chmod +x run.sh

CMD ["./run.sh"]
