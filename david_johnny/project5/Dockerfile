# Use OpenJDK as base and install Scala
FROM eclipse-temurin:17-jdk

# Install Scala 3.3.1 (stable version)
ENV SCALA_VERSION=3.3.1
ENV SCALA_HOME=/usr/share/scala

RUN apt-get update && \
    apt-get install -y curl && \
    curl -fL "https://github.com/lampepfl/dotty/releases/download/${SCALA_VERSION}/scala3-${SCALA_VERSION}.tar.gz" | tar xz -C /tmp && \
    mv /tmp/scala3-${SCALA_VERSION} ${SCALA_HOME} && \
    ln -s ${SCALA_HOME}/bin/scala /usr/bin/scala && \
    ln -s ${SCALA_HOME}/bin/scalac /usr/bin/scalac && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the Scala source file
COPY Main.scala .

# Compile the Scala program
RUN scalac Main.scala

# Run the program (can be overridden with parameters)
CMD ["scala", "Main"]