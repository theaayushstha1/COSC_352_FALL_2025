FROM hseeberger/scala-sbt:17.0.2_1.6.2_3.1.1

WORKDIR /app

# Copy the Scala source file and data
COPY HomicideAnalysis.scala .
COPY homicides.csv .

# Compile the Scala program
RUN scalac HomicideAnalysis.scala

# Run the program
CMD ["scala", "HomicideAnalysis"]
