# Use an official Scala image
FROM openjdk:17-slim

# Install Scala
RUN apt-get update && apt-get install -y scala && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy project files
COPY . /app

# Compile the Scala code
RUN scalac project4.scala

# Run the program
CMD ["scala", "BaltimoreHomicideAnalyzer"]
