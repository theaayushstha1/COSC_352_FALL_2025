# Use official Python image
FROM python:3.12-slim

# Set working directory inside container
WORKDIR /app

# Copy your project files into the container
COPY . .

# Run your Python script when the container starts
CMD ["python", "table.py"]
