# Use OpenJDK with Scala support
FROM hseeberger/scala-sbt:11.0.12_1.5.5_2.13.6

# Set working directory
WORKDIR /app

# Copy source files
COPY BaltimoreHomicideAnalysis.scala /app/

# Compile the Scala program
RUN scalac BaltimoreHomicideAnalysis.scala

# Default command runs without arguments (stdout)
# Arguments can be passed when running the container
CMD ["scala", "BaltimoreHomicideAnalysis"]
