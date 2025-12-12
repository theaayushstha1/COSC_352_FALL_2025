# Baltimore Homicides Functional Programming Tool (Clojure)

## Analyses
1. **Seasonal Distribution of Homicides**  
   Groups homicide counts by season (Winter, Spring, Summer, Fall) to reveal seasonal trends.

2. **Average Victim Age by Weapon Type**  
   Calculates the mean age of victims for each weapon category, highlighting demographic differences.

## How to Run
```bash
docker build -t homicide-tool .
docker run --rm homicide-tool

## Findings
- Homicides peak in summer (437 cases) and are lowest in winter (371 cases).
- Firearm victims average 32.2 years old, while stabbing victims average 41.6 years old.
- Strangulation cases show the youngest victims, averaging 21 years old.