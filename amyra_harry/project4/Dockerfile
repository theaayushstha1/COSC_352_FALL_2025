FROM eclipse-temurin:11-jdk

# Install Scala
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://downloads.lightbend.com/scala/2.13.14/scala-2.13.14.deb -o scala.deb && \
    apt install -y ./scala.deb && \
    rm scala.deb && \
    apt-get clean

# Set working directory
WORKDIR /app

# Copy the Scala source file
COPY BaltimoreHomicideAnalysis.scala .

# Compile the Scala program
RUN scalac BaltimoreHomicideAnalysis.scala

# Run the program
CMD ["scala", "BaltimoreHomicideAnalysis"]
