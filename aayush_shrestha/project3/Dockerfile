FROM python:3.9

# Set working directory where host files will be mounted
WORKDIR /data

# Copy the script into /app
COPY read_html_table.py /app/read_html_table.py

# Default entrypoint
ENTRYPOINT ["python", "/app/read_html_table.py"]