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

# Copy and install Python dependencies (if any)
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt || true

# Copy application files
COPY get_mine.py .
COPY The_article.scala .
COPY info_death.csv .

# Compile Scala code
RUN scalac The_article.scala

# Run the analysis
CMD ["scala", "BaltimoreHomicideAnalysis"]