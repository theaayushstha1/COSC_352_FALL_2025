FROM openjdk:11-jdk-slim

# Install Scala, Python and dependencies
RUN apt-get update && \
    apt-get install -y wget python3 python3-pip ca-certificates && \
    wget -q https://downloads.lightbend.com/scala/2.13.12/scala-2.13.12.tgz && \
    tar -xzf scala-2.13.12.tgz -C /usr/share && \
    ln -s /usr/share/scala-2.13.12/bin/scala /usr/bin/scala && \
    ln -s /usr/share/scala-2.13.12/bin/scalac /usr/bin/scalac && \
    rm scala-2.13.12.tgz && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt || true

# Copy application files (DON'T copy info_death.csv - it will be mounted at runtime)
COPY get_mine.py .
COPY the_article.scala .

# At container start: compile the scala source into /app/classes and run with that classpath.
# The "--" after the sh -c script allows docker to pass runtime args into "$@" inside the script.
ENTRYPOINT ["sh", "-c", "mkdir -p /app/classes && scalac -d /app/classes the_article.scala && scala -cp /app/classes BaltimoreHomicideAnalysis \"$@\"", "--"]

# default argument (can be overridden by `docker run ...`)
CMD ["--output=stdout"] 