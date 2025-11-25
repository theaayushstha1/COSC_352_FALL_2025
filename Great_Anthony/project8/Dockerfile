FROM clojure:temurin-21-lein-alpine

WORKDIR /app

# Copy project files
COPY project.clj /app/
COPY src /app/src/
COPY baltimore_homicides_combined.csv /app/

# Download dependencies
RUN lein deps

# Compile the application
RUN lein uberjar

# Run the application
CMD ["java", "-jar", "target/homicide-analyzer-1.0.0-standalone.jar"]
