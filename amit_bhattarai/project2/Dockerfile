# Use a lightweight Python image
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy the Python script
COPY read_html_table.py .

# Set the default command to run the script
CMD ["python", "read_html_table.py", "https://en.wikipedia.org/wiki/Comparison_of_programming_languages"]
