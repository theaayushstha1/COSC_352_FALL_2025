# Project 6 — Go Port of Project 5

**Author:** Amit Bhattarai  
**COSC 352**

---

## Overview
This project is a Go (Golang) version of Project 5.  
It scrapes Baltimore homicide data (2020–2025) from [chamspage.blogspot.com](https://chamspage.blogspot.com)  
and answers two questions:
1. How many victims age 18 or younger were killed each year?  
2. What is the total number of homicide victims each year?

---

## How to Run
```bash
./run.sh               # prints to terminal
./run.sh --output=csv  # saves to out/output.csv
./run.sh --output=json # saves to out/output.json
Example output:
2020 | under18=24 | total=348
2021 | under18=23 | total=340
...
Notes
Built using Go 1.22, only standard libraries.
Fully Dockerized for easy execution.
Includes CA certificates fix for HTTPS sites.
Produces the same results as Project 5.
