# Project 4: Baltimore Homicide Data Analysis in (Scala) 

## Overview
This project analyzes Baltimore City homicide data (2023–2025) from [Cham's Page](https://chamspage.blogspot.com/) to provide actionable insights for the Mayor's office and Police Department.  

It addresses two main questions:  
1. **District Clearance Rate Analysis:** Which police districts are most effective at closing homicide cases?  
2. **Police Camera Effectiveness Analysis:** Do homicides near surveillance cameras get solved at higher rates, and should more cameras be installed?

---

## Key Findings (Example Output)
**District Clearance Rates:**  
- Eastern: 62.2% (best performing)  
- Western: 20.2% (needs attention)  
- City average: 43.4%  

**Camera Effectiveness:**  
- Homicides near cameras: 46.8% clearance  
- Homicides away from cameras: 38.4% clearance  
- 38.5% of homicides occur near cameras  
- Recommendation: Expand camera coverage in high-crime areas  

---

## Technical Details
- **Language:** Scala 3.1.1  
- **Runtime:** JVM (OpenJDK 17)  
- **Containerization:** Docker  
- **Data Source:** Cham's Page (public Baltimore homicide tracking)

---

## Project Structure

---

## How to Run

### Quick Start
```bash
# Navigate to project directory
cd project4

# Make script executable
chmod +x run.sh

# Build and run analysis
./run.sh

# Build Docker image
docker build -t project4 .

# Run analysis in container
docker run --rm project4
