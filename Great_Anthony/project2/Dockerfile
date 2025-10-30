FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt* ./

# Install Python dependencies
# RUN pip install --no-cache-dir \
#     pandas \
#     numpy \
#     matplotlib \
#     seaborn \
#     openpyxl \
#     xlsxwriter

# Copy your project files
COPY Lang2.py ./
COPY *.csv ./

# Set environment variable to ensure Python output is sent straight to terminal
ENV PYTHONUNBUFFERED=1

# Command to run your application
CMD ["python", "Lang2.py"]