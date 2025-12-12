# Turing Machine Simulator - Docker Container
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first (for caching)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose Flask port
EXPOSE 5000

# Set environment variables
ENV FLASK_APP=app/app.py
ENV PYTHONUNBUFFERED=1

# Run the application
CMD ["python", "app/app.py"]