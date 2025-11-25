FROM clojure:temurin-21-tools-deps-1.11.1.1413

WORKDIR /app

# Copy project files
COPY deps.edn /app/
COPY src /app/src/
COPY baltimore_homicides_combined.csv /app/

# Download dependencies
RUN clojure -P

# Run the analysis
CMD ["clojure", "-M", "-m", "core"]