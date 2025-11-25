# Multi-stage build for Clojure application
FROM clojure:temurin-21-lein-2.11.2 AS builder

# Set working directory
WORKDIR /app

# Copy project files
COPY project.clj /app/
COPY src /app/src/

# Build the uberjar
RUN lein uberjar

# Runtime stage - smaller image
FROM eclipse-temurin:21-jre-alpine

# Set working directory
WORKDIR /app

# Copy the uberjar from builder stage
COPY --from=builder /app/target/uberjar/baltimore-homicides-0.1.0-standalone.jar /app/baltimore-homicides.jar

# Copy the CSV file (will be mounted at runtime)
COPY baltimore_homicides_combined.csv /app/baltimore_homicides_combined.csv

# Run the application
ENTRYPOINT ["java", "-jar", "/app/baltimore-homicides.jar"]
CMD ["baltimore_homicides_combined.csv"]