# Project 8: Baltimore Homicide Analysis - Functional Programming

## Author
**Raegan Green**  
COSC 352 - Fall 2025  
**Language:** Clojure

---

## Chosen Analyses

### 1. Homicides by Year with Trend Analysis
Analyzes temporal patterns to identify if Baltimore is becoming safer or more dangerous over time. Uses `reduce` to count homicides per year and `map` to calculate year-over-year percentage changes.

### 2. Geographic Hotspot Analysis  
Identifies the most dangerous locations in Baltimore to guide police resource allocation. Uses `reduce` to count incidents per location and `filter` to extract top 15 hotspots.

---

## How to Run

```bash
chmod +x run.sh
./run.sh
```

The program will:
1. Build a Docker container with Clojure
2. Parse the CSV data into immutable records
3. Execute both analyses using pure functions
4. Display results in formatted tables

**Alternative (Docker command):**
```bash
docker build -t homicide-functional-analysis .
docker run --rm homicide-functional-analysis
```

---

## Interesting Findings

### Temporal Trends
- **Deadliest Year:** 2022 with 353 homicides
- **Dramatic Improvement:** Homicides dropped 58% from 2022 (353) to 2025 (147)
- **Sustained Decline:** Three consecutive years of decreasing homicides (2023-2025)
- **2025 Trend:** 34.4% decrease from 2024, suggesting interventions are working

**Insight:** Baltimore has seen the most significant crime reduction in recent history, potentially due to improved policing strategies, community programs, or demographic shifts.

### Geographic Distribution
- **Top Location:** Edmondson Avenue (20 homicides)
- **Concentration:** Top 15 locations account for only 11.7% of total homicides
- **Wide Distribution:** 1,305 unique locations across the city
- **Street Type Pattern:** Avenues (9) are more dangerous than streets (3) or roads (2)

**Insight:** Unlike cities with concentrated "hot zones," Baltimore homicides are widely distributed. This suggests systemic citywide issues rather than isolated neighborhood problems. Police cannot simply focus on a few areas—crime prevention must be comprehensive across all neighborhoods.

### Additional Statistics
- **Case Closure Rate:** Only 25.2% of cases solved (low clearance rate)
- **Average Victim Age:** 32.8 years (prime working age)
- **Youth Victims:** 247 victims aged ≤18 (14.6% are children/teens)

**Insight:** The low closure rate (25%) means 3 out of 4 murders go unsolved, which undermines deterrence and community trust in law enforcement.

---

## Functional Programming Approach

All analysis logic uses **pure functions**:
- ✅ `map`, `filter`, `reduce` for data transformation
- ✅ No mutation (immutable data structures)
- ✅ No I/O inside analysis functions
- ✅ Composable, testable functions
- ✅ Pattern matching via destructuring

**Example:**
```clojure
(defn homicides-by-year [records]
  (->> records
       (filter #(> (:year %) 0))
       (map :year)
       (reduce (fn [acc year]
                 (update acc year (fnil inc 0)))
               {})))
```

---

## Technical Details

**Dataset:** 1,695 homicide records (2020-2025)  
**Language:** Clojure 1.11.1  
**Runtime:** JVM (Temurin 21)  
**Container:** Docker with Alpine Linux  
**Pure Functional:** Zero mutations, side-effect-free analysis  

---

## Project Structure
```
project8/
├── src/homicide_analysis/core.clj  # Main program (330 lines)
├── baltimore_homicides_combined.csv # Data
├── deps.edn                         # Clojure config
├── Dockerfile                       # Container
├── run.sh                           # Run script
└── README.md                        # This file
```