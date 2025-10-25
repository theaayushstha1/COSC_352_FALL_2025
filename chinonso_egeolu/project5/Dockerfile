FROM hseeberger/scala-sbt:11.0.12_1.5.5_2.13.6

WORKDIR /app

# Copy all files from root
COPY HomicideAnalysis.scala ./
COPY build.sbt ./

# Compile the Scala application
RUN sbt compile

# Set working directory for output files
WORKDIR /output

# Copy compiled files to output directory
RUN cp -r /app/target /output/target && \
    cp /app/build.sbt /output/ && \
    cp /app/HomicideAnalysis.scala /output/

# Create an entrypoint script to handle arguments
RUN echo '#!/bin/bash\nsbt "run $*"' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]