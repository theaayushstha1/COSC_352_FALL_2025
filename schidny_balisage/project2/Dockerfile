FROM python:3.11-slim

LABEL maintainer="your-email@example.com"
LABEL description="HTML Table Extractor - Convert web tables to CSV"
LABEL version="1.0"

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY table_extractor.py .

RUN mkdir -p /app/output && \
    chmod 755 /app/output

RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app
USER app

VOLUME ["/app/output"]

ENTRYPOINT ["python", "table_extractor.py"]
CMD []
