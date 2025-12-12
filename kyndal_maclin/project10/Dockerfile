# Use Python 3.11 slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=app.py

# Copy requirements file
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY turing_machine.py .
COPY app.py .
COPY cli.py .
COPY templates/ templates/

# Make cli.py executable
RUN chmod +x cli.py

# Expose port for web interface
EXPOSE 5000

# Default command (can be overridden)
CMD ["python", "app.py"]