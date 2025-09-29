FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY project_3.py .

ENV DEFAULT_URLS="https://en.wikipedia.org/wiki/Programming_languages_used_in_most_popular_websites,https://www.tiobe.com/tiobe-index/,https://github.com/quambene/pl-comparison"


CMD ["python", "project_3.py"]
#HAD TO RUN WITH VOLUME MOUNT TO CREATE THE FOLDER AND ZIP
# docker run -v "$(pwd)/website_tables:/app/website_tables" project3_docker
