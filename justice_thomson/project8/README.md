# Baltimore Homicides Analysis Tool

This project is a small analytical tool written in **Haskell** (pure functional style) to analyze the Baltimore homicides dataset from the provided CSV file.

## Chosen Analyses
**Homicides per Year:** Counts the total number of homicides grouped by year.  
**Distribution of Homicide Types:** Classifies each homicide as Shooting, Stabbing, or Other based on keywords in the notes field and counts the distribution.

##  How to Run
1. Ensure `Main.hs`, `Dockerfile`, and `baltimore_homicides_combined.csv` are in the same directory.  
2. Build the Docker image:  
   docker build -t baltimore-analysis .  
3. Run the container:  
   docker run baltimore-analysis

## 🔍 Interesting Findings
Running the tool on the dataset reveals:  
- Homicide totals vary significantly by year, with some years showing notable peaks (2020 exceeds 300 cases; run the tool for exact CSV-based totals).  
- **Shootings are the most common homicide type**, by a large margin.  
- **Stabbings are far less frequent**, and **Other** includes blunt-force trauma, arson, and additional non-categorized causes.

