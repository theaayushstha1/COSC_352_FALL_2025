FROM openjdk:11-jdk

# Update package manager and install Scala
RUN apt-get update && \
    apt-get install -y scala && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the Scala source code
COPY BmoreHomicide.scala .

# Compile the Scala program
RUN scalac BmoreHomicide.scala

# Default command runs with stdout output
# Can be overridden with: docker run <image> scala BmoreHomicide --output=csv
CMD ["scala", "BmoreHomicide"]
