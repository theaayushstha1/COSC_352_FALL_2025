FROM python:3.10-slim

WORKDIR /app

# Install lxml for HTML parsing
RUN pip install lxml

# Copy your Python script into the container
COPY extract_tables.py .

# Set the entrypoint to run your script
ENTRYPOINT ["python", "extract_tables.py"]
