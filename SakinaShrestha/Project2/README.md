\# Project 2 – HTML Table Parser

&nbsp;

This project uses a Python script inside a Docker container to extract tables from a webpage (or local HTML file) and save them as CSV files.



\# Files Included



\- `read\_html\_table.py` – Python script for parsing HTML tables

\- `Dockerfile` – Docker configuration to run the script

\- `README.md` – Instructions







\# How to Build the Docker Image



Run this inside the `project2/sakina\_shrestha/` folder:



```bash

docker build -t html-table-parser .



How to Run the Script



docker run --rm -v "${PWD}:/app" html-table-parser python3 /app/read\_html\_table.py "https://en.wikipedia.org/wiki/Comparison\_of\_programming\_languages" table



This command will:



Download the webpage



Extract up to 5 tables



Save them as table\_1.csv, table\_2.csv, etc. in your current folder



