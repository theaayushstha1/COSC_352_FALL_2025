# Use base image with Scala
FROM openjdk:11

# Install Scala
RUN apt-get update && apt-get install -y scala && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy project files into the container
COPY . /app

# Default command: compile and run the Scala program each time
ENTRYPOINT ["bash", "-c", "scalac BaltimoreHomicideAnalyzer.scala && scala BaltimoreHomicideAnalyzer $0 $@"]
