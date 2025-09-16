# Use a lightweight Python image
FROM python:3.10-slim

# Set working directory inside the container
WORKDIR /app

# Copy your Python script into the container
COPY read_html_table.py .

# Install any dependencies your script needs
RUN pip install --no-cache-dir requests beautifulsoup4

# Set the entrypoint so the script runs automatically
ENTRYPOINT ["python", "read_html_table.py"]
