FROM python:3.11-slim

# Create a non-root user
RUN adduser --disabled-password --gecos '' kamari

# Set working directory and switch to user
WORKDIR /app
USER kamari

# Copy all files into the container
COPY . .

# Default command (can be overridden)
CMD ["python3", "parse_tables.py"]