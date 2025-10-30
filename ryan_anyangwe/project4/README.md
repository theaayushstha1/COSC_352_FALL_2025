# Project 4: Baltimore City Homicide Analysis

## Student Information
**Name:** Ryan Anyangwe  
**Course:** COSC 352 Fall 2025  
**Date:** October 2025

## Overview
This project analyzes Baltimore City homicide statistics from chamspage.blogspot.com to provide actionable insights for the Mayor's office and Police Department. The analysis is implemented in Scala, containerized with Docker.

## Research Questions

### Question 1: District-Level Resource Allocation
**Which police districts have the worst homicide  rates and highest concentration of unsolved cases, indicating where  resources are most critically needed?**

This analysis identifies districts requiring immediate investigative support and quantifies resource gaps.

### Question 2: Temporal Crime Prevention
**What are the patterns of homicides over multiple years to optimize preventive patrol deployment?**

This analysis enables proactive deployment of patrol resources based on crime patterns, like summer time being more deadly for teens etc.

## How to Run

### Prerequisites
- Docker installed and running
- Git

### Instructions

1. Clone the repository:
```bash
git clone https://github.com/B3nterprise/project4.git
cd project4
```

2. Make run.sh executable:
```bash
chmod +x run.sh
```

3. Run the analysis:
```bash
./run.sh
```

The script will automatically:
- Check if Docker image exists
- Build the image if needed (takes 2-3 minutes first time)
- Run the Scala program in a container
- Display analysis results

## Technical Details

- **Language:** Scala 2.13.6
- **Runtime:** JVM (OpenJDK 11)
- **Container:** Docker
- **Libraries:** Native Scala/Java only

## Output

The program outputs two comprehensive analyses:
1. District closure rates with resource recommendations
2. Monthly homicide patterns with deployment strategies

## Files
- `BaltimoreHomicideAnalysis.scala` - Main analysis program
- `Dockerfile` - Container configuration
- `run.sh` - Execution script
