Baltimore Homicides Functional Analysis
Author: Sakina Shrestha
Course: COSC 352 — Fall 2025

Overview
This project performs data analysis on the Baltimore homicide dataset using pure functional programming in Haskell. Two main analyses are implemented:

Weapon Type Distribution: Categorizes and counts homicides by weapon (e.g., Shooting, Stabbing)
Top 10 Neighborhoods by Homicide Incidence: Displays which address blocks had the highest number of cases

All analysis logic is written with pure functions, with no mutation or impure data access.

Files Included
project8/
├── main.hs                              # Haskell source code
├── baltimore_homicides_combined.csv     # Homicide dataset
├── Dockerfile                           # Docker configuration
└── README.md                            # This file

Functional Design

Defines a custom, immutable Haskell record type for homicide records
Uses functional constructs like pattern matching, folds, maps, and filters
All analytical code is pure; only the main function handles I/O
Dockerized for reproducible results on any system


How to Run
Build the Docker Image
bashdocker build -t baltimore_analysis_image .
Run the Analysis
bashdocker run --rm baltimore_analysis_image
The output will display weapon statistics and the top 10 neighborhoods by homicide count.

Chosen Analyses
Analysis 1: Weapon Type Distribution
Homicides are categorized by method, showing how many cases involved each weapon type (Shooting, Stabbing, Blunt Force, etc.).
Analysis 2: Top Neighborhoods
Output lists the ten most frequent address blocks associated with homicide cases, identifying geographic hotspots.

Interesting Findings

Firearm Prevalence: Most homicides involve firearms ("Shooting" category)
Geographic Concentration: A handful of Baltimore neighborhoods experience substantially higher homicide rates
Data Quality: Some data entries are missing or malformed and were filtered from the analysis
