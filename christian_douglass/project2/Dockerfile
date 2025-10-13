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

RUN pip install pandas beautifulsoup4 lxml html5lib

# Copy your script into the image
# 🔁 If your file has a different name, change this line + CMD below
COPY king.py /app/

RUN mkdir -p /app/out && chown -R appuser:appuser /app && chmod 755 /app/king.py
USER appuser

# Default command: run the script, writing CSVs to /app/out
CMD ["python", "king.py"]
