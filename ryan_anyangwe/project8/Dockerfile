# Use official Clojure image
FROM clojure:temurin-21-lein-alpine

# Set working directory
WORKDIR /app

# Copy source files
COPY analysis.clj /app/
COPY baltimore_homicides_combined.csv /app/

# Run the Clojure program
CMD ["clojure", "analysis.clj"]