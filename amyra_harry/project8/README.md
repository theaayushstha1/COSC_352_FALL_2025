# Baltimore Homicides Functional Analysis

**Language:** Clojure  
**Author:** Myra  
**Course:** COSC 352 - Functional Programming

---

## Chosen Analyses

### 1. Homicides Per Year
Counts total homicides for each year using `reduce`.

### 2. Trend Analysis  
Calculates if homicides are increasing, decreasing, or stable over time using `reduce` to fold over year-by-year data.

### 3. Weapon-Type Distribution
Analyzes weapon types (Shooting, Stabbing, Blunt Force, etc.) by parsing the "Notes" field. Uses `map` and `reduce`.

---

## Functional Programming Features

- **Pure Functions**: All analysis logic has no side effects
- **Immutable Data**: Uses `defrecord` and persistent data structures
- **Higher-Order Functions**: Extensive use of `map`, `filter`, `reduce`
- **No Mutations**: Zero mutable state
- **Separation of I/O**: Pure analysis functions separated from file reading/printing

---

## How to Run

### Build Docker Image
```bash
docker build -t baltimore-homicides .
```

### Run Analysis
```bash
docker run baltimore-homicides
```

---

## Project Structure

```
project8/
├── Dockerfile
├── project.clj
├── baltimore_homicides_combined.csv
├── README.md
└── src/
    └── baltimore_homicides/
        └── core.clj
```

---

## Key Findings

- **83% of homicides involve firearms** (shootings)
- **Summer months (July, May, August) have the highest rates**
- **Ages 26-35 are most affected** (98 victims)
- **February has the lowest homicide count**

---

## CSV Format Expected

```
No.,Date Died,Name,Age,Address Block Found,Notes,...
```

Date format: MM/DD/YY (e.g., 01/02/20)

---

## Example Output

```
Total homicides in dataset: 336

━━━ HOMICIDES PER YEAR ━━━
2020:  336 homicides

━━━ WEAPON-TYPE DISTRIBUTION ━━━
Shooting            :  279 victims (83.0%)
Stabbing            :   18 victims (5.4%)
Other/Unknown       :   17 victims (5.1%)

━━━ AGE DISTRIBUTION ━━━
26-35     :   98 victims
18-25     :   85 victims
```