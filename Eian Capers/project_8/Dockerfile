FROM clojure:temurin-21-lein-alpine

WORKDIR /app

RUN apk add --no-cache curl

COPY project.clj .
COPY src/ ./src/

RUN lein deps

RUN curl -o baltimore_homicides_combined.csv \
  "https://raw.githubusercontent.com/professor-jon-white/COSC_352_FALL_2025/be5df82c2e4aea13f2becf14f11fab1eac549baa/professor_jon_white/func_prog/baltimore_homicides_combined.csv"

RUN lein uberjar

RUN ls -la target/

CMD ["sh", "-c", "java -jar target/uberjar/homicides-analysis-*-standalone.jar baltimore_homicides_combined.csv"]
