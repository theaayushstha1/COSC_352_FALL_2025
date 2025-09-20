FROM python:3.12-slim

WORKDIR /app

COPY table_2_csv.py .

RUN mkdir -p /app/output
RUN adduser --disabled-password --gecos "" --no-create-home scraper

RUN chown -R scraper:scraper /app

USER scraper

ENTRYPOINT ["python", "table_2_csv.py"]