FROM python:3.11-slim

# Install PyPDF2
RUN pip install PyPDF2

WORKDIR /app

# Copy source files
COPY pdfsearch.py .
COPY Morgan_2030.pdf .

# Make executable
RUN chmod +x pdfsearch.py

# Create symlink for easier usage
RUN ln -s pdfsearch.py pdfsearch

ENTRYPOINT ["python3", "pdfsearch.py"]