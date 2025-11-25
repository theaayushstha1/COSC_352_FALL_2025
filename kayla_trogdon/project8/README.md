# Project 8: Baltimore Homicides Functional Analysis (Clojure)

## Overview
This project analyzes Baltimore City homicide statistics (2021-2025) using functional programming in Clojure. It performs statistical analysis on weapon types and neighborhood comparisons using pure functional programming techniques.
How to Run

## How to run:

1) bash:
     chmod +x run.sh

2) Run the project
    bash./run.sh

View the analysis results in your terminal

## Project Components

### src/core.clj → Main Clojure Program
Functional programming implementation for homicide data analysis

Pure functional data structures: Homicide records with immutable data
- Weapon Type Analysis: Extracts and categorizes weapons (shooting, stabbing, blunt force, etc.)
- Neighborhood Analysis: Identifies top 20 most dangerous locations

Key Functional Programming Features:

- Immutable data structures using defrecord
- Pure functions for all analysis logic
- Threading macros (->>) for data transformation pipelines
- Higher-order functions (map, filter, frequencies, sort-by)
- No side effects in analysis functions

### deps.edn → Clojure Dependencies
Project configuration file

- Specifies Clojure version and required libraries
- Includes org.clojure/data.csv for CSV parsing

### Dockerfile
Creates containerized Clojure environment

- Uses clojure:temurin-21-tools-deps-1.11.1.1413 as base image
- Copies source code and CSV data into container
- Pre-downloads all dependencies
- Runs the analysis program

### run.sh → Orchestration Script
Automates the complete workflow

- Checks if baltimore_homicides_combined.csv exists
- Builds Docker image with Clojure environment
= Runs the functional analysis in container
= Displays results in terminal

### baltimore_homicides_combined.csv → Data File
Combined homicide data from 2021-2025

Contains 1,695 homicide records
10 columns: No, Date Died, Name, Age, Address Block, Notes, Criminal History, Surveillance, Case Closed, Year

## Analysis Output
The program generates 2 main analyses:

- Weapon Type Distribution
-- Breakdown of homicide methods with percentages
-- Categories: Shooting, Stabbing, Blunt Force, Strangulation, Arson, etc.
-- Shows count and percentage for each weapon type

- Top 20 Most Dangerous Neighborhoods
-- Ranked list of locations by homicide count
-- Shows address blocks with highest incidents
-- Displays rank, address, and total homicides