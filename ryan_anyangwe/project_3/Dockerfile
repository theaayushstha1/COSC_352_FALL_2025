FROM python:3.9-slim

WORKDIR /app

# Install required packages
RUN pip install --no-cache-dir pandas beautifulsoup4 lxml html5lib requests

# Copy the parser script
COPY table_parser.py /app/

# Set entrypoint
ENTRYPOINT ["python", "/app/table_parser.py"]
