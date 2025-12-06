# Multi-stage build for Clojure application
FROM clojure:temurin-21-lein-2.11.2 AS builder

# Set working directory
WORKDIR /app

# Copy project files
COPY project.clj .
COPY src ./src

# Download dependencies and build uberjar
RUN lein uberjar

# Runtime stage - minimal JRE
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Copy the uberjar from builder
COPY --from=builder /app/target/uberjar/baltimore-homicide-analysis-1.0.0-standalone.jar /app/app.jar

# Run the application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
CMD ["baltimore_homicides_combined.csv"]
