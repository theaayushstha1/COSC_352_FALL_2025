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

# Copy application files
COPY get_mine.py .
COPY the_article.scala .
COPY info_death.csv .


RUN mkdir -p /app/classes
# Compile Scala code
# Compile Scala code into that directory at build time (safe/optional)
RUN scalac the_article.scala



# At container start: compile the scala source into /app/classes and run with that classpath.
# The "--" after the sh -c script allows docker to pass runtime args into "$@" inside the script.
ENTRYPOINT ["sh","-c","scalac -d classes the_article.scala && exec scala -cp classes BaltimoreHomicideAnalysis \"$@\"","--"]

# default argument (can be overridden by `docker run ...`)
CMD ["--output=csv"]