FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY read_html_table.py /app/read_html_table.py

RUN mkdir -p /app/output

ENTRYPOINT ["python", "/app/read_html_table.py"]

