FROM clojure:openjdk-17-tools-deps

WORKDIR /app

COPY deps.edn .
COPY src ./src
COPY baltimore_homicides_combined.csv .

CMD ["clojure", "-M:run"]
