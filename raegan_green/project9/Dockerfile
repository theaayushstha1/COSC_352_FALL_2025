# Mojo PDF Search Tool - Dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install pypdf

# Install Mojo (this requires modular CLI - users will need to have Mojo installed)
# For now, we'll document that Mojo must be installed on the host system

WORKDIR /app

# Copy the search tool
COPY pdfsearch.mojo .

# Note: This Dockerfile assumes Mojo is installed
# Run with: mojo pdfsearch.mojo <pdf> <query> <n>
CMD ["echo", "Please run: mojo pdfsearch.mojo <pdf_file> <query> <num_results>"]