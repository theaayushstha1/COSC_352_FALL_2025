# Project 6: Baltimore Homicide Analysis (Go Implementation)

## Overview
This project is a **Go (Golang)** version of Project 5, which was originally implemented in **Scala**.  
It performs the same analysis of Baltimore homicide data but demonstrates the differences between Scala’s JVM-based design and Go’s compiled, lightweight approach.

The program outputs the analysis results in **text**, **CSV**, or **JSON** format.

---

## How to Run

### Step 1: Navigate to the project folder
```bash
cd project6

### Step 2: Make the script executable
chmod +x run.sh

# Default (text output to terminal)
./run.sh

# CSV output
./run.sh --output=csv

# JSON output
./run.sh --output=json

### Step 4: Verify output files
ls -lh output/

### Key Differences Between Scala and Go

| Feature               | Scala (Project 5)       | Go (Project 6)            |
| --------------------- | ----------------------- | ------------------------- |
| **Runtime**           | Requires JVM            | Compiles to native binary |
| **Startup Time**      | 2–3 seconds             | <100 milliseconds         |
| **Memory Usage**      | 200–500 MB              | 10–50 MB                  |
| **Error Handling**    | Try/Catch exceptions    | Explicit error checks     |
| **Concurrency Model** | Futures and Actors      | Goroutines and Channels   |
| **Code Style**        | Functional and abstract | Simple and explicit       |
| **Use Case Strength** | Complex data logic      | Systems and microservices |
