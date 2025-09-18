# Dockerfile
# Minimal image with Python 3
FROM python:3.12-slim

# Keep Python output unbuffered and avoid .pyc files
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create non-root user (safer)
RUN useradd -ms /bin/bash appuser

# App directory
WORKDIR /app

# Copy your script into the image
# 🔁 If your file has a different name, change this line + CMD below
COPY king.py /app/

# Create default output folder and set permissions
RUN mkdir -p /app/out && chown -R appuser:appuser /app
USER appuser

# Default command: run the script, writing CSVs to /app/out
CMD ["python", "king.py", "--out", "/app/out"]
