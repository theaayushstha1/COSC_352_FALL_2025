FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy the script
COPY table_extractor.py .

# Create output directory for CSV files
RUN mkdir -p /app/output

# Set the output directory as volume
VOLUME ["/app/output"]

# Make script executable
RUN chmod +x table_extractor.py

# Default command
ENTRYPOINT ["python", "table_extractor.py"]   
