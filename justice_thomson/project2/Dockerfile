# Use standard Python image
FROM python:3.9-slim


# Set working directory
WORKDIR /app


# Copy the Python script
COPY project2.py .


# Default: run the script, but let you pass arguments
ENTRYPOINT ["python", "project2.py"]
# Run code as docker run <image name> <url with table to extract>
# Use slim Python
FROM python:3.9-slim

WORKDIR /app
COPY project2.py .

# Always run project2.py by default
ENTRYPOINT ["python", "project2.py"]

