# Use Python 3.11 slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ ./src/
COPY examples/ ./examples/
COPY tests/ ./tests/

# Create non-root user for security
RUN useradd -m -u 1000 tmuser && \
    chown -R tmuser:tmuser /app

# Switch to non-root user
USER tmuser

# Set environment variable
ENV PYTHONUNBUFFERED=1

# Default command shows help
ENTRYPOINT ["python", "-m", "src.cli"]
CMD ["--help"]