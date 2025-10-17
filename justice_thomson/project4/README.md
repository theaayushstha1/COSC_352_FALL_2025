# Project 4: Baltimore Homicide Analysis

This project analyzes Baltimore homicide data from https://chamspage.blogspot.com/ using Scala. It answers two questions about the 2025 data:

1. How many homicides occurred in each month of 2025? (To identify seasonal trends for better resource allocation. Note: Data is up to October 2025, so later months may show 0.)
2. What is the impact of surveillance cameras on case closure rates in 2025 homicides? (To evaluate if cameras improve solve rates, informing policy on surveillance expansion.)

## How to Run
- Ensure Docker is installed (it is in Codespaces).
- Run `./run.sh` (builds the image if needed and runs the container).

The output will display the questions and data rows.

## Dependencies
- Only native Scala/Java libraries (e.g., scala.io.Source for fetching/parsing).
- Data fetched live from the blog URL.
- Uses Java 21 for the JVM.

## Notes
- The parsing handles the blog's text format by cleaning HTML and extracting entries.
- Tested in GitHub Codespaces.
