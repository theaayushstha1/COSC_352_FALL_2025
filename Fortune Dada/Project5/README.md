Project 5

This project continues from Project 4. I modified my Scala program so it can output in three formats: normal stdout (default), csv, and json. You can choose which format to use by adding a flag when you run the program.

Usage:
./run.sh                     -> prints to screen (default)
./run.sh --output=csv         -> writes data to csv files
./run.sh --output=json        -> writes data to json files
./run.sh --output=csv --out-dir=./out  -> optional custom folder

The csv and json files include the results for both questions from project 4:
- Question 1: number and percent of homicide victims aged 60 or older per year (2020–2025)
- Question 2: relationship between nearby CCTV and case closure (2024–2025)

Data format:
For csv and json, I used simple lowercase field names like year, sixty_plus_count, total, and share_pct for Q1, and group, closed, open, total, closure_rate_pct for Q2. The goal was to make it easy for everyone’s data to be merged together later.

Default output folder is /out (or whatever folder you set with --out-dir).
The Dockerfile builds and runs the program using scala-cli. You can mount a folder to save your csv or json results.
