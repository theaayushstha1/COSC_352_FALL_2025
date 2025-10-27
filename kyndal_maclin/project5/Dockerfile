# ===============================
# Baltimore Homicide Analysis
# Scala 3 + Jsoup + Docker
# ===============================

FROM openjdk:25-slim

# Install curl and unzip
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*

# Install Scala CLI
RUN curl -fLo scala-cli.gz https://github.com/VirtusLab/scala-cli/releases/download/v1.9.1/scala-cli-x86_64-pc-linux.gz && \
    gunzip scala-cli.gz && \
    mv scala-cli /usr/local/bin/scala-cli && \
    chmod +x /usr/local/bin/scala-cli

# Set working directory
WORKDIR /app

# Copy all project files
COPY . .

# Pre-compile Scala source (optional, speeds up runtime)
RUN scala-cli compile BaltimoreHomicideAnalysis.scala

# ✅ Correct entrypoint
ENTRYPOINT ["scala-cli", "run", "BaltimoreHomicideAnalysis.scala", "--"]

