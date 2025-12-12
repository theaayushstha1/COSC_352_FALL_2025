FROM gcc:latest

# Install dependencies
RUN apt-get update && apt-get install -y \
    make \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy source files
COPY turing_machine.h /app/
COPY turing_machine.cpp /app/
COPY examples.cpp /app/
COPY main.cpp /app/
COPY Makefile /app/

# Build the application
RUN make

# Run the application
CMD ["./turing_machine"]