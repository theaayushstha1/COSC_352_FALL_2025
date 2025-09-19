# Project2: Dockerized Web Scraper

A Python web scraper that extracts HTML tables and saves them as CSV files, containerized with Docker.

## Features

- Scrapes web pages and downloads HTML content
- Extracts all tables from HTML and saves as CSV files
- Fully containerized with Docker
- Cross-platform compatibility

## Usage

### Build the Docker image:
\```bash
docker build -t web-scraper .
\```

### Run the scraper:
\```bash
# Save files to host machine
docker run -v $(pwd)/output:/app/output web-scraper "YOUR_URL_HERE"

# Example:
docker run -v $(pwd)/output:/app/output web-scraper "https://example.com/page-with-tables.html"
\```

### Output
- HTML file: `[page_name].html`
- CSV files: `[page_name]_table_[number].csv`

## Requirements

- Docker installed on your system
- Internet connection for web scraping

## Dependencies

- Python 3.11
- pandas
- lxml
- html5lib
- beautifulsoup4

