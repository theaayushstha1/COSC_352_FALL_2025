Baltimore Homicides Functional Analysis
Author: Sakina Shrestha

Overview
This project performs data analysis on the Baltimore homicide dataset using pure functional programming in Haskell. Two main analyses are included:

Weapon Type Distribution: Categorizes and counts homicides by weapon (e.g., Shooting, Stabbing).

Top 10 Neighborhoods by Homicide Incidence: Displays which address blocks had the highest number of cases.

All analysis logic is written with pure functions, with no mutation or impure data access.

Files Included
main.hs — Haskell source code

baltimore_homicides_combined.csv — Homicide dataset

Dockerfile — For containerized build and run

README.md — Project documentation (this file)

Functional Design
Defines a custom, immutable Haskell record type for homicide records.

Uses functional constructs like pattern matching, folds, maps and filters.

All analytical code is pure; only the main function deals with I/O.

Dockerized for reproducible results on any system.

How to Run
Build the Docker image:

text
docker build -t baltimore_analysis_image .
Run the analysis:

text
docker run --rm baltimore_analysis_image
The output will show weapon statistics and the top 10 neighborhoods by homicide count.

Chosen Analyses
Weapon Type Distribution:
Homicides are categorized by method, showing how many cases involved each weapon type.

Top Neighborhoods:
Output lists the ten most frequent address blocks associated with homicide cases.

Interesting Findings
Most homicides involve firearms (“Shooting” category).

A handful of Baltimore neighborhoods experience substantially higher homicide rates.

Some data entries are missing or malformed, and were filtered from the top neighborhoods analysis.

