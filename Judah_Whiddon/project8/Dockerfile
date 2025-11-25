FROM erlang:alpine

WORKDIR /app

COPY src ./src
COPY data ./data

RUN erlc src/*.erl

CMD ["erl", "-noshell", "-s", "main", "start", "-s", "init", "stop"]
