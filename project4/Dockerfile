FROM openjdk:17-jdk-slim
WORKDIR /app

# Install sbt
RUN apt-get update && apt-get install -y curl gnupg dirmngr ca-certificates && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list && \
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x99E82A75642AC823" | apt-key add - || true && \
    apt-get update && apt-get install -y sbt && \
    rm -rf /var/lib/apt/lists/*

COPY . /app

# Try to assemble a fat jar. If assembly isn't available, compile to ensure dependencies are fetched.
RUN sbt -v assembly || sbt -v compile

CMD ["/usr/bin/sbt", "run"]
