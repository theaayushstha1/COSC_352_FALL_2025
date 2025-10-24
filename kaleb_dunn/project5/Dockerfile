# Use official Scala image with JVM
FROM hseeberger/scala-sbt:17.0.2_1.6.2_3.1.1

# Set working directory
WORKDIR /app

# Copy source file
COPY BaltimoreHomicideAnalysis.scala .

# Compile the Scala program
RUN scalac BaltimoreHomicideAnalysis.scala

# Run the program
CMD ["scala", "BaltimoreHomicideAnalysis"]