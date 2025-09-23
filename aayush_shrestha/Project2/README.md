# Project 2 - Dockerized Project 1

# Name : Aayush Shrestha
# ID: 00367844 

This project dockerizes Project 1 (`read_html_table.py`) so it can run inside a Docker container.

## Files
- `read_html_table.py` → Python script from Project 1
- `Dockerfile` → Docker instructions
- `README.md` → Instructions
- `page.html` → Local copy of the Wikipedia page used for testing

## Build Instructions
From inside this folder:

```bash
docker build -t docker_project1 .

