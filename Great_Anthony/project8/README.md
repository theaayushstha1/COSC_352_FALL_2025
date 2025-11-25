# Baltimore Homicide Analysis Tool

A functional programming project built in Clojure to analyze Baltimore homicide data.

## Chosen Analyses

This tool performs two key analyses on the Baltimore homicides dataset:

### 1. Temporal Trend Analysis
- **Purpose**: Track homicide incidents by year and month
- **Method**: Groups homicides by year-month periods and counts occurrences
- **Output**: Time-series view showing monthly homicide patterns

### 2. Weapon Type Distribution
- **Purpose**: Analyze the distribution of weapons used in homicides
- **Method**: Categorizes and counts homicides by weapon type
- **Output**: Ranked list of weapon types with counts and percentages

## Functional Programming Features

This implementation demonstrates pure functional programming principles:

- **Immutable Data**: Uses Clojure records and immutable data structures
- **Pure Functions**: All analysis functions are pure (no side effects)
- **Higher-Order Functions**: Extensive use of `map`, `filter`, `reduce`, `frequencies`
- **Function Composition**: Uses threading macros (`->>`) for clean data pipelines
- **Pattern Matching**: Type definitions with `defrecord`
- **No Mutation**: All transformations create new data structures

## How to Run

### Prerequisites
- Docker installed on your system

### Using Docker

1. **Build the Docker image**:
```bash
   docker build -t homicide-analyzer .
```

2. **Run the analysis**:
```bash
   docker run homicide-analyzer
```

### Alternative: Local Execution (requires Leiningen)

1. **Install dependencies**:
```bash
   lein deps
```

2. **Run directly**:
```bash
   lein run
```

3. **Build standalone JAR**:
```bash
   lein uberjar
   java -jar target/homicide-analyzer-1.0.0-standalone.jar
```

## Project Structure
```
project8/
├── src/
│   └── homicide_analyzer.clj    # Main Clojure source code
├── baltimore_homicides_combined.csv  # Data file
├── project.clj                   # Leiningen project configuration
├── Dockerfile                    # Docker containerization
└── README.md                     # This file
```

## Interesting Findings

Based on the analysis of the Baltimore homicides dataset:

1. **Temporal Patterns**: 
   - Certain months show higher incident rates
   - Year-over-year trends reveal patterns in violence
   - Seasonal variations in homicide rates

2. **Weapon Distribution**:
   - Firearms represent the overwhelming majority of incidents
   - This highlights the prevalence of gun violence in Baltimore
   - Clear dominance of shooting-related homicides

3. **Data Quality Observations**:
   - Comprehensive date information allows temporal analysis
   - Weapon classification enables distribution analysis
   - Large dataset provides statistical significance

## Technical Implementation Details

### Pure Functional Core
All analysis logic is implemented using pure functions that:
- Take immutable data as input
- Produce new data as output
- Have no side effects (except for I/O in main function)

### Data Pipeline
The analysis follows a clear functional pipeline:
```
CSV File → Parse → Records → Transform → Aggregate → Format → Display
```

Each step uses functional constructs like `map`, `filter`, `reduce`, and `frequencies`.

## Authors

Created for COSC 352 Functional Programming course.
