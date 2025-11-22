# Baltimore Homicides Analysis - Haskell

**COSC 352 Fall 2025 - Project 8**

## Chosen Analyses

1. **Homicides Per Year with Trend Analysis** - Yearly counts, solve rates, year-over-year trends
2. **Victim Age Demographics** - Age group distribution and solve rates by demographic

## How to Run
```bash
chmod +x run.sh
./run.sh
```

## Functional Programming Concepts Demonstrated

| Concept | Implementation |
|---------|---------------|
| Immutable Data | `Homicide`, `YearStats`, `AgeGroupStats` record types |
| Pattern Matching | `ageToGroup`, `parseField`, `isClosed` functions |
| map | Transforming lists to statistics |
| filter | Selecting closed cases, filtering age groups |
| fold | Grouping by year, calculating totals |
| List Comprehensions | `groupByAgeGroup` function |
| Pure Functions | All analysis logic is side-effect free |

## Interesting Findings

- The 18-34 age group represents the largest proportion of homicide victims
- Case solve rates vary significantly by year and victim demographic
- Year-over-year trends reveal patterns in Baltimore's homicide rates
