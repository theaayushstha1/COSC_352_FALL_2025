# Project 6 — Go (Golang) CLI using Project 5 Data

This project reuses the homicide dataset from Project 5 and re-implements the same three analyses in **Go**:

- **Q1 — Monthly Totals:** incidents per month in a selected year
- **Q2 — District Totals:** incidents per police district (falls back to weapon if district missing)
- **Q3 — Weekday Distribution:** incidents per weekday (Sunday→Saturday)

This project highlights how both languages solve the same analytical problem differently. Scala’s functional abstractions make data manipulation concise and expressive, while Go emphasizes simplicity, speed, and readability. The Go version is easier to deploy and more efficient for containerized or lightweight environments.

## Build & Run

### Native (in Codespaces)
```bash
make build

# Q1 (text)
./bin/project6 --input ./data/homicides.csv --year 2025 --question q1 --out text

# Q2 (json)
./bin/project6 --input ./data/homicides.csv --year 2025 --question q2 --out json

# Q3 (csv)
./bin/project6 --input ./data/homicides.csv --year 2025 --question q3 --out csv
