# Project 4 — Scala + Docker: Baltimore Homicide Data (2020–2025)

**Author:** Amit Bhattarai

## How to Run
From this `project4/` directory:
```bash
./run.sh

The script builds a Docker image (if needed) and runs a Scala program that:
Fetches yearly homicide tables from https://chamspage.blogspot.com
Answers two questions:
Question 1
How many homicide victims were age 18 or younger in each year (2020–2025)?
Question 2
What is the total number of homicide victims in each year (2020–2025)?
Libraries: Only Scala/Java standard libraries (HttpClient, regex).
Docker: Uses openjdk:17-slim with scala installed.
