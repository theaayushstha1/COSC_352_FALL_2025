# FROM hseeberger/scala-sbt:11.0.6_1.3.10_2.13.1

# WORKDIR /app
# COPY scala-scraper .

# RUN sbt compile
# ENTRYPOINT ["sbt", "run", "commands"]

FROM hseeberger/scala-sbt:11.0.6_1.3.10_2.13.1

WORKDIR /app

# Copy the entire scala-scraper directory
COPY scala-scraper /app

# Compile the project
RUN sbt compile

# Create output directory
RUN mkdir -p /app/output

# Create an entrypoint script that uses sbt run with arguments
RUN echo '#!/bin/bash' > /app/entrypoint.sh && \
    echo 'cd /app && sbt "run $@"' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]

