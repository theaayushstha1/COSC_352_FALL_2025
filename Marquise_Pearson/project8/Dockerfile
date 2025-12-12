FROM clojure:temurin-21-tools-deps

WORKDIR /app

COPY deps.edn .
RUN clj -P

COPY src ./src
COPY resources ./resources

CMD ["clj", "-M:run"]
