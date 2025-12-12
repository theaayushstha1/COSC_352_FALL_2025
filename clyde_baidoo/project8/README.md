### Chosen Analyses

This project implements all **4 comprehensive analyses**:

1. **Homicides Per Year with Trend Analysis**
   - Aggregates homicide counts by year
   - Calculates linear regression trend (increasing/decreasing/stable)
   - Shows percentage distribution across time periods

2. **Top 10 Neighborhoods by Homicide Count**
   - Identifies most affected neighborhoods
   - Ranks by frequency
   - Calculates percentages of total incidents

3. **Weapon Type Distribution**
   - Categorizes weapons used in homicides
   - Ranks by frequency
   - Shows percentage breakdown

4. **Victim Demographics Analysis**
   - Calculates average victim age
   - Breaks down by race with percentages
   - Breaks down by gender with percentages

## 🚀 Quick Start

### Prerequisites
- Install docker
- The CSV data file found here --> professor_jon_white/func_prog/baltimore_homicides_combined.csv - https://github.com/professor-jon-white/COSC_352_FALL_2025/blob/be5df82c2e4aea13f2becf14f11fab1eac549baa/professor_jon_white/func_prog/baltimore_homicides_combined.csv

### Run in 3 Steps

```bash
# 1. Make the bash script executable
chmod +x run.sh

# 2. Run everything (auto-generates sample data, builds and runs docker)
./run.sh

# 3. Done! View results in the terminal
```

## 🐳 Docker Commands

### Build the Image
```bash
docker build -t baltimore-homicides .
```

### Run the Analysis
```bash
# Analyze the default CSV file
docker run --rm -v $(pwd):/data baltimore-homicides /data/baltimore_homicides_combined.csv

# Analyze a different CSV file
docker run --rm -v $(pwd):/data baltimore-homicides /data/your_custom_file.csv

# Mount a different directory
docker run --rm -v /path/to/your/data:/data baltimore-homicides /data/homicides.csv
```

## 💡 Key Findings

Based on the sample dataset analysis:

### Geographic Concentration
- **Cherry Hill and Downtown** account for 37.5% of all the homicides data

### Weapon Patterns
- **Handguns dominate** at 70.8% of all homicides
- Firearms (handguns + rifles) represent nearly 80% of weapon use


### Demographic Patterns
- **Average victim age: 29.4 years** - young adults are primary victims
- **75% male victims** - significant gender disparity
- **83.3% Black victims** - indicates profound racial disparities requiring policy attention

### Temporal Trends
- Sample data shows consistent yearly patterns

### Functional Programming Principles/Constructs Used
✅ `map` - Transform lists  
✅ `filter` - Select elements  
✅ `fold` / `reduce` - Aggregate data  
✅ `filter_map` - Parse with error handling    
✅ Pattern matching - Safe data extraction  
```

### Compilation
```bash
# Native compilation for performance
ocamlopt -o homicide_analysis homicide_analysis.ml
```

### Compile Locally (Without Docker)

If you have OCaml installed:

```bash
# Install OCaml (if needed)
# macOS: brew install ocaml
# Ubuntu: apt-get install ocaml

# Compile
ocamlopt -o homicide_analysis homicide_analysis.ml

# Run
./homicide_analysis baltimore_homicides_combined.csv
```

### Requirements
- OCaml 4.14 or higher
- No external dependencies (uses standard library only)

