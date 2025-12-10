FROM python:3.12-slim

WORKDIR /app

# Copy project files
COPY . /app

RUN pip install --no-cache-dir -r requirements.txt || true

# Make main.py executable
RUN chmod +x /app/main.py

ENTRYPOINT ["python", "main.py"]
CMD []
