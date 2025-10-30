FROM hseeberger/scala-sbt:11.0.12_1.5.5_2.13.6

WORKDIR /app

# Create output directory
RUN mkdir -p /app/output

# Copy all project files
COPY build.sbt .
COPY src/ src/

# Compile the Scala program
RUN sbt clean compile

# Run the program
CMD ["sbt", "run"]
