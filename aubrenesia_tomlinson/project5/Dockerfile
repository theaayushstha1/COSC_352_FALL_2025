# Use official Scala + SBT image
FROM hseeberger/scala-sbt:17.0.2_1.6.2_3.1.1

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Pre-build project to speed up container runs
RUN sbt compile

CMD ["sbt", "-batch", "-Dsbt.supershell=false", "-Dsbt.log.noformat=true", "runMain BmoreHomicideStats"]
