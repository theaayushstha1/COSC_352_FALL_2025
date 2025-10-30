Project 5 - Output formats for Baltimore Homicide data

This document explains the CSV and JSON formats produced by the updated Project 4 program.

Files produced
- homicides_2025.csv: Comma-separated values file with header:
  no,date,name,age,address,notes,criminalHistory,camera,caseClosed
  Each row represents a single homicide record. Fields that contain commas, quotes or newlines are wrapped in double quotes and double quotes are escaped by doubling them.

- homicides_2025.json: A JSON array of objects. Each object has the following fields:
  {
    "no": string,
    "date": string,
    "name": string,
    "age": number|null,
    "address": string,
    "notes": string,
    "criminalHistory": string,
    "camera": string,
    "caseClosed": string
  }
  The JSON is plain UTF-8 with simple escaping for backslashes, quotes, and newlines.

Design choices
- I kept the field names short and stable so downstream reporting tools can map them easily.
- Ages that are missing are written as empty in CSV and null in JSON.
- The program writes files into the working directory with fixed filenames `homicides_2025.csv` and `homicides_2025.json` so automation can reliably pick them up. If you prefer different names, modify `Main.scala` or wrap the program in a script.

Usage
- Default behavior (no flag) prints the original textual analysis to stdout:
  ./run.sh

- Write CSV:
  ./run.sh --output=csv
  This will build (if needed) and run the docker image; when the Scala program finishes it will write `homicides_2025.csv` in the container's working directory. To access the file from the host you can mount the project directory into the container or update the Dockerfile/CMD to copy it out. For class submission, ensure your Docker image copies outputs into a known location or run the program locally.

- Write JSON:
  ./run.sh --output=json

Notes on Docker and file access
- Current `run.sh` forwards the `--output` flag into the container. The files produced are inside the container's filesystem. To persist them to the host, run the container with a bind mount, for example:
  docker run --rm -v "$PWD":/app project4-baltimore:latest --output=csv

This README is intentionally concise; reach out if you want the program to accept a `--out-file=PATH` argument or to stream results to stdout as CSV/JSON instead of writing files.
