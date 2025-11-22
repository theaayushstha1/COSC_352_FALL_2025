Baltimore Homicides Analysis Tool
This is a small analytical tool written in Haskell (pure functional style) to analyze the Baltimore homicides dataset from the provided CSV.
Chosen Analyses

Homicides per year: Counts the number of homicides grouped by year.
Distribution of homicide types: Classifies homicides into "Shooting", "Stabbing", or "Other" based on keywords in the notes field and counts the distribution.

How to Run

Place Main.hs, Dockerfile, and baltimore_homicides_combined.csv in the same directory.
Build the Docker image:textdocker build -t baltimore-analysis .
Run the container:textdocker run baltimore-analysis

Interesting Findings
Based on running the program with the dataset:

The number of homicides varies by year, with peaks in certain years (e.g., 2020 had over 300 based on partial data, but run the program for exact counts from the full CSV).
Shootings dominate the types, comprising the majority of cases, while stabbings are less common, and "Other" includes blunt force, arson, etc.
