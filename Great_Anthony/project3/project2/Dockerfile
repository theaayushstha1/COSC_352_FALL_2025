FROM python:3.12-slim

WORKDIR /app

RUN pip install --no-cache-dir requests beautifulsoup4 lxml pandas html5lib

COPY scraper.py /app/

ENTRYPOINT ["python", "scraper.py"]
