# Use official Scala image with SBT
FROM hseeberger/scala-sbt:17.0.2_1.6.2_3.1.1

# Set working directory
WORKDIR /app

# Copy source files
COPY BmoreAnalysis.scala .

# Compile the Scala program
RUN scalac BmoreAnalysis.scala

# Set entrypoint to run compiled class
ENTRYPOINT ["java", "-cp", "/app", "BmoreAnalysis"]
