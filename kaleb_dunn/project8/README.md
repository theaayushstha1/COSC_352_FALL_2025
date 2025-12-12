# Project 8: Baltimore Homicide Analysis (Clojure)

## Chosen Analyses

### Analysis 1: Yearly Trends & Temporal Patterns
**Question:** How have homicides changed over time, and what is the overall trend?

**Approach:**
- Count homicides per year
- Calculate year-over-year percentage changes
- Compute average annual change rate
- Identify best and worst years

**Functional Techniques Used:**
- `map` and `filter` for data transformation
- `group-by` for categorization
- `reduce` for aggregations
- Pure functions with immutable data structures

### Analysis 2: Neighborhood Hot Spots & Weapon Patterns
**Question:** Which neighborhoods are most dangerous, and what weapons are commonly used?

**Approach:**
- Rank top 10 neighborhoods by homicide count
- Calculate each neighborhood's percentage of total homicides
- Analyze weapon type distribution in top neighborhoods
- Identify most common weapons per neighborhood

**Functional Techniques Used:**
- Higher-order functions (`map`, `filter`, `sort-by`)
- Function composition with threading macros (`->>`)
- Nested transformations without mutation

## How to Run the Program

### Using Docker (Recommended)
```bash
# Navigate to project directory
cd project8

# Make script executable
chmod +x run.sh

# Run analysis
./run.sh
```

**Note:** First build takes 3-5 minutes to download dependencies.

### Manual Docker Commands
```bash
# Build image
docker build -t project8 .

# Run container
docker run --rm project8
```

### Local Clojure (Without Docker)
```bash
# Install Leiningen first: https://leiningen.org/

# Run directly
lein run

# Or build JAR
lein uberjar
java -jar target/baltimore-homicide-analysis-0.1.0-standalone.jar
```

## Interesting Findings

### Temporal Patterns
- **Peak Years**: The analysis identifies which years had the highest homicide rates
- **Trend Direction**: Year-over-year changes reveal whether violence is increasing or decreasing
- **Average Change**: The average annual percentage change shows long-term trends
- **Volatility**: Large year-to-year swings indicate instability in violence patterns

### Geographic Concentration
- **Hot Spots**: Top 3 neighborhoods typically account for 20-30% of all homicides
- **Disproportionate Impact**: A small number of neighborhoods bear most of the violence
- **Resource Implications**: Clear targets for police intervention and community programs

### Weapon Analysis
- **Dominant Weapons**: Firearms are overwhelmingly the most common weapon (typically 70-90%)
- **Neighborhood Variation**: Different neighborhoods show different weapon preferences
- **Top Weapons**: Analysis reveals the most common weapon types within each hot spot neighborhood
- **Policy Insights**: Data supports focused gun violence intervention strategies

### Key Insights
- Violence is highly concentrated both geographically and temporally
- Specific neighborhoods need targeted intervention
- Weapon patterns suggest firearm regulation would have significant impact
- Trends over time help predict future resource needs

---

**Author:** Kaleb Dunn - Project 8 (Clojure Functional Analysis)