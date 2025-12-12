FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Make CLI executable
RUN chmod +x cli.py

# Expose port for web interface
EXPOSE 5000

# Default command runs web interface
CMD ["python", "app.py"]
