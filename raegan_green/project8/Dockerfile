FROM clojure:temurin-21-tools-deps-alpine

WORKDIR /app

# Copy project files
COPY deps.edn /app/
COPY src/ /app/src/
COPY baltimore_homicides_combined.csv /app/

# Pre-download dependencies
RUN clojure -P

# Run the analysis
CMD ["clojure", "-M:run"]
