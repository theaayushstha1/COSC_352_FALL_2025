# Project 4: Baltimore Homicide Statistics Analysis

## Overview
This project analyzes Baltimore homicide statistics from 2024 to identify patterns and insights that could help the police department and mayor's office. The analysis is performed using Scala and runs in a Docker container.

## Research Questions

### Question 1: Which neighborhoods have the lowest solve rates?
This question identifies neighborhoods with the poorest case closure rates, helping the police department allocate resources to areas where investigations are least effective. By understanding geographical patterns in solve rates, law enforcement can identify systemic issues in specific areas and implement targeted interventions.

### Question 2: What's the relationship between victim demographics and case outcomes?
This analysis examines how factors such as victim age, criminal history, and surveillance camera presence correlate with case closure rates. Understanding these relationships can help identify potential biases in investigation resource allocation, determine the effectiveness of surveillance infrastructure, guide policy decisions on victim support services, and inform community policing strategies for different demographic groups.

## Data Source
Data is fetched from the Baltimore Homicide Statistics blog maintained by citizen journalist Chams at https://chamspage.blogspot.com/

## Technical Implementation

### Requirements
- Docker installed on your system
- Internet connection to fetch homicide data

### Files
- BaltimoreHomicideAnalysis.scala - Main Scala program that fetches and analyzes data
- Dockerfile - Builds a container with JDK and Scala to compile and run the program
- run.sh - Shell script that orchestrates the Docker build and execution
- README.md - This file

### How to Run
1. Make the run script executable: chmod +x run.sh
2. Execute the script: ./run.sh

The script will check if the Docker image exists, build the image if needed, run the analysis in a container, display the results, and clean up the container.

## Implementation Notes
- Uses only native Scala/Java libraries (no external dependencies)
- Fetches live data from the source website
- Handles edge cases (missing data, malformed entries)
- Filters for statistical relevance (minimum 3 cases per neighborhood)
- Provides both raw numbers and percentages for easy interpretation

## Author
Created for COSC 44031 - Fall 2025
Morgan State University

## Data Acknowledgment
Homicide data maintained by Chams at https://chamspage.blogspot.com/
