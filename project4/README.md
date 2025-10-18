# Project 4: Baltimore City Homicide Analysis
**Author:** Amit Bhattarai  
**Course:** COSC 352 - Fall 2025  
**Language:** Scala (native libraries only)  
**Containerized with:** Docker  

---

## Overview
This project analyzes Baltimore City homicide data directly scraped from [Cham’s Page](https://chamspage.blogspot.com), an open-source record of homicides in Baltimore.  
It uses only native Scala and Java libraries (no external dependencies) to perform live web scraping, pattern extraction, and statistical analysis.

---

## Data Source
The program fetches data from:
- [2025 Homicide List](https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html)
- [2024 Homicide List](https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html)

---

## Research Questions
### 🕵️ Question 1:
**Which Baltimore district had the largest spike or drop in homicides between 2024 and 2025?**  
> This question helps city leadership identify which areas are improving or worsening in terms of violence, allowing targeted policy responses.

### 👥 Question 2:
**What was the average victim age per district in 2024–2025, and which district had the highest average age?**  
> This provides demographic insight for the Mayor’s Office and law enforcement, helping understand which age groups are most impacted.

---

## Technical Details
- **Built with:** Scala 2.13.12  
- **Build tool:** sbt  
- **Docker base image:** `sbtscala/scala-sbt:eclipse-temurin-jammy-17.0.9_9_1.9.7_2.13.12`
- **Run command:** `./run.sh`
- **Main class:** `Main`

---

## How to Run
```bash
# 1. Build the Docker image
docker build -t homicide-scala:latest .

# 2. Execute the analysis
./run.sh

