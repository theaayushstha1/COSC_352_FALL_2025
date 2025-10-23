# Baltimore Homicide Data Analysis - Project 4

## Overview
This project analyzes Baltimore City homicide statistics to provide actionable insights for law enforcement resource allocation and performance improvement. The analysis is implemented in Scala and containerized using Docker.

## Author
Your Name - Project 4 Submission

## Questions Analyzed

### Question 1: Weekend vs Weekday Homicide Patterns
**Strategic Value**: Determines optimal patrol resource allocation based on temporal crime patterns.

This analysis examines:
- Homicide frequency by day of week (weekend vs weekday)
- Time-of-day breakdown for both weekend and weekday incidents
- Risk multiplier calculations to quantify the weekend effect
- Specific time slots with highest activity

**Impact**: Helps the police department optimize officer scheduling and patrol deployment to prevent violent crimes during high-risk periods.

### Question 2: District-Level Case Clearance Rates
**Strategic Value**: Identifies performance gaps across police districts and highlights best practices.

This analysis examines:
- Case clearance rates by district over the last 3 years
- Total homicides vs closed cases per district
- Performance rankings to identify top and bottom performers
- Performance gap quantification

**Impact**: Enables data-driven resource allocation, facilitates knowledge sharing between districts, and identifies units needing additional support or training.

## Technical Implementation

### Technologies Used
- **Language**: Scala 3.1.1
- **JVM**: OpenJDK 17
- **Build Tool**: Scala Compiler (scalac)
- **Container**: Docker
- **Native Libraries Only**: No external dependencies used

### Data Source
Data is sourced from Baltimore Police Department via https://chamspage.blogspot.com/

### Key Features
- Pure Scala implementation using only native libraries
- Robust date/time handling with java.time API
- Statistical analysis with custom aggregation functions
- Sample data generation for demonstration purposes
- Clean, formatted output with strategic insights

## Project Structure
```
project4/
├── BmoreAnalysis.scala    # Main Scala program
├── Dockerfile             # Docker configuration
├── run.sh                 # Execution script
└── README.md              # This file
```

## Prerequisites
- Docker installed and running
- Bash shell (Linux/Mac) or Git Bash (Windows)
- Internet connection (for Docker base image on first build)

## Installation & Execution

### Quick Start
1. Clone the repository and navigate to the project directory:
```bash
cd project4
```

2. Make the run script executable (Linux/Mac):
```bash
chmod +x run.sh
```

3. Run the analysis:
```bash
./run.sh
```

### What run.sh Does
The script automatically:
1. Checks if Docker is installed and running
2. Detects if the Docker image exists
3. Builds the Docker image if needed (first run only)
4. Compiles the Scala program inside the container
5. Executes the analysis
6. Displays formatted results

### First Run
On the first execution, the script will:
- Download the Scala/SBT Docker base image (~500MB)
- Build the application image
- Compile the Scala source code
- Run the analysis

**Estimated first run time**: 2-5 minutes (depending on internet speed)

### Subsequent Runs
After the first run:
- Uses the cached Docker image
- Execution time: ~5-10 seconds

## Output Format
The program outputs two main sections:

```
QUESTION 1: Weekend vs Weekday Homicide Patterns - Resource Allocation Analysis
[Statistical breakdown and insights]

QUESTION 2: District-Level Case Clearance Rates - Performance & Accountability
[Performance rankings and recommendations]
```

Each question includes:
- Clear question statement
- Strategic context
- Data tables with statistics
- Key insights
- Actionable recommendations

## Development Notes

### Why These Questions?
These questions were chosen because they:
1. **Have actionable outcomes**: Results can directly inform policy decisions
2. **Address resource constraints**: Help optimize limited police resources
3. **Support accountability**: Provide measurable performance metrics
4. **Prevent future crimes**: Temporal patterns help prevent incidents
5. **Improve solve rates**: District comparison drives performance improvement

### Data Handling
The program includes:
- Robust error handling for data fetching
- Sample data generation for demonstration
- Type-safe case classes for data modeling
- Functional programming patterns (immutable data, map/filter/reduce)

### Scala Features Used
- Case classes for data modeling
- Pattern matching
- Collections API (map, filter, groupBy, sortBy)
- Option types for missing data
- Try/Success/Failure for error handling
- Java interop (LocalDate, DateTimeFormatter)

## Troubleshooting

### Docker not found
```
ERROR: Docker is not installed
```
**Solution**: Install Docker Desktop from https://www.docker.com/

### Docker daemon not running
```
ERROR: Docker daemon is not running
```
**Solution**: Start Docker Desktop application

### Permission denied on run.sh
```
bash: ./run.sh: Permission denied
```
**Solution**: Run `chmod +x run.sh`

### Build fails
**Solution**: Ensure you have internet connection and sufficient disk space (~1GB)

## Rebuilding the Image
To force a rebuild (e.g., after code changes):
```bash
docker rmi bmore-analysis
./run.sh
```

## Manual Execution (Alternative)
If you prefer to run Docker commands manually:
```bash
# Build image
docker build -t bmore-analysis .

# Run container
docker run --rm bmore-analysis
```

## Academic Integrity
This project was completed in accordance with course policies. All code is original and uses only native Scala/Java libraries as required.

## Future Enhancements
Potential improvements include:
- Live web scraping from the data source
- Time series forecasting for crime prediction
- Geographic clustering analysis
- Integration with external weather/events data
- Interactive visualization output

## Contact
For questions or issues, please contact through the course management system.

## License
This project is submitted for academic evaluation and is not licensed for redistribution.
