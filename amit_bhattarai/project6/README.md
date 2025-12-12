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
## Scala vs Go — Key Differences

| Feature | Scala (Project 5) | Go (Project 6) |
|----------|-------------------|----------------|
| **Runtime** | Runs on the JVM (needs Java) | Compiles to a standalone binary |
| **Execution Speed** | Slower startup (JVM load time) | Instant startup |
| **Dependencies** | Needs Java + Scala runtime | None — only Go binary |
| **Syntax & Style** | Functional & object-oriented | Simpler, procedural |
| **Error Handling** | Exceptions / Try-Catch | Explicit `error` returns |
| **Concurrency** | Uses threads / futures | Uses lightweight goroutines |
| **Build Size** | ~300 MB Docker image | ~20 MB Docker image |
| **HTTP & I/O** | `java.net.http` | `net/http` |
| **JSON/CSV Output** | Manual string building | Native `encoding/json`, `encoding/csv` |

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
---


