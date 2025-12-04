# Use official Mojo image (or Python + Mojo)
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install PyPDF2 for PDF extraction
RUN pip install PyPDF2

# Install Mojo (if available, otherwise use modular)
# For now, we'll assume Mojo is installed or use a Mojo-compatible base
RUN pip install modular || true

# Set working directory
WORKDIR /app

# Copy source file
COPY pdfsearch.mojo /app/

# Default entrypoint
ENTRYPOINT ["mojo", "run", "pdfsearch.mojo"]
CMD ["--help"]