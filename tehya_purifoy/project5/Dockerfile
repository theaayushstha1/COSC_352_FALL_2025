FROM hseeberger/scala-sbt:11.0.12_1.5.5_2.13.6

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Create necessary directories
RUN mkdir -p data output target/scala-2.13/classes

# Compile the application
RUN scalac -d target/scala-2.13/classes src/main/scala/CrimeDataApp.scala

# Make scripts executable
RUN chmod +x build.sh run.sh

# Default command (can be overridden)
CMD ["./run.sh"]
