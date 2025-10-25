FROM mozilla/sbt:8u292_1.5.4

# Install necessary tools
RUN apt-get update && apt-get install -y wget curl

# Set working directory
WORKDIR /app

# Copy the build file and source code
COPY build.sbt .
COPY src ./src

# Download dependencies and compile
RUN sbt compile

# Download Baltimore crime data
RUN mkdir -p /data && \
    cd /data && \
    wget https://data.baltimorecity.gov/api/views/wsfq-mvij/rows.csv?accessType=DOWNLOAD -O BPD_Part_1_Victim_Based_Crime_Data.csv

# Set the entrypoint to run the Spark application
ENTRYPOINT ["sbt", "run"]
