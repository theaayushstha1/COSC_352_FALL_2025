# Use a lightweight Python base image
FROM python:3.11-slim

# Set the working directory inside the container
WORKDIR /app

# Copy your Python script into the container
COPY html_table_to_csv.py /app/

# Set the default command to run the script
ENTRYPOINT ["python", "html_table_to_csv.py"]
