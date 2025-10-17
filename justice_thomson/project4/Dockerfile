FROM openjdk:21-jdk

# Install Scala (using official distribution)
RUN apt-get update && apt-get install -y wget unzip
RUN wget https://downloads.lightbend.com/scala/3.5.1/scala3-3.5.1.zip && \
    unzip scala3-3.5.1.zip && \
    mv scala3-3.5.1 /usr/local/scala && \
    rm scala3-3.5.1.zip
ENV PATH="${PATH}:/usr/local/scala/bin"

# Copy and compile the Scala file
COPY Project4.scala /app/
WORKDIR /app
RUN scalac Project4.scala

# Run the program
CMD ["scala", "Project4"]
