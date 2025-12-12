# Use official Clojure image
FROM clojure:temurin-21-lein-alpine

# Set working directory
WORKDIR /app

# Copy project files
COPY project.clj /app/
COPY src /app/src/

# Download dependencies
RUN lein deps

# Compile the project
RUN lein uberjar

# Run the application
CMD ["java", "-jar", "target/baltimore-homicide-analysis-0.1.0-standalone.jar"]