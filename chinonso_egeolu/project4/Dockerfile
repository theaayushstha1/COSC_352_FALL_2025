FROM hseeberger/scala-sbt:11.0.12_1.5.5_2.13.6

WORKDIR /app

# Copy all files from root
COPY HomicideAnalysis.scala ./
COPY build.sbt ./

# Compile the Scala application
RUN sbt compile

# Run the application
CMD ["sbt", "run"]