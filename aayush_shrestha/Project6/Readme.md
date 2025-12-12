# Project 6: Baltimore Homicide Analysis - Golang Port

**Author:** Aayush Shrestha  
**Course:** COSC 352 - Fall 2025  
**Institution:** Morgan State University  
**Date:** October 31, 2025

---

## Project Overview

This project ports Project 5's Baltimore City homicide data analysis from **Scala** to **Golang**, maintaining identical functionality while leveraging Go's native features including goroutines, channels, and standard library packages. The program analyzes Baltimore homicide statistics to identify violence hotspots and age-targeted intervention opportunities.

---

## Key Features

- ✅ **Three output formats**: stdout (terminal), CSV, and JSON
- ✅ **Dockerized deployment**: Multi-stage builds for minimal image size (~10MB vs Scala's ~350MB)
- ✅ **Concurrent data fetching**: Goroutines with timeout handling
- ✅ **Zero external dependencies**: Uses only Go standard library
- ✅ **Identical analysis results**: Same metrics as Scala implementation

---

## Usage

Make script executable (first time only)
chmod +x run.sh

Default output to terminal
./run.sh

Generate CSV file
./run.sh --output=csv

Generate JSON file
./run.sh --output=json


**Prerequisites:** Docker Desktop installed and running

---

## Scala vs Golang: Key Differences

### Language Paradigm
- **Scala**: Multi-paradigm (OOP + Functional), runs on JVM, complex type system
- **Golang**: Imperative with simple types, compiles to native code, composition over inheritance

### Concurrency
**Scala:**
val future = Future {
fetchData


**Golang:**
go func() {
data := fetchData
) ch <-

Go's goroutines are lightweight (~2KB) vs threads (~1MB), enabling millions of concurrent operations.

### Error Handling
- **Scala**: Exception-based with try-catch blocks
- **Golang**: Explicit error returns - `data, err := fetchData()`

### Performance Comparison

| Metric | Scala (Project 5) | Golang (Project 6) |
|--------|-------------------|---------------------|
| Image Size | ~350MB | ~10MB |
| Build Time | 30-60s | 5-10s |
| Startup | 2-3s | <100ms |
| Memory | 200-300MB | 10-20MB |

---

## Go-Specific Features Demonstrated

1. **Goroutines**: Async data fetching with timeout
2. **Channels**: Type-safe communication between concurrent routines
3. **Defer**: Automatic resource cleanup
4. **Struct Tags**: Native JSON serialization
5. **Multi-stage Docker Builds**: Security and size optimization

---

## Project Structure

Project6/
├── main.go # Main Golang implementation
├── go.mod # Module definition
├── dockerfile # Multi-stage Docker build
├── run.sh # Execution script
├── README.md # This file
├── baltimore_homicide_analysis.csv # Generated CSV output

---

## Analysis Outputs

### CSV Structure
- Metadata: Total homicides, closure rate, critical zones
- Location hotspots with closure rates and demographics
- Age group analysis
- Complete raw data

### JSON Structure
Hierarchical format with:
- `analysis_metadata`: Summary statistics
- `location_hotspots`: Geographic analysis
- `age_group_analysis`: Demographic patterns
- `raw_homicide_data`: Individual records

---

## Sample Results

**Total Homicides:** 25  
**Overall Closure Rate:** 56%  
**Critical Zones (3+ cases):** 1

**Top Hotspot:** 1200 block N Broadway (3 cases, 33% closure rate)

**Most Affected Age Group:** Adults 26-40 (9 cases, 67% closure rate)

---

## Implementation Highlights

- **Standard Library Only**: No external dependencies (encoding/csv, encoding/json, net/http)
- **Idiomatic Go**: Proper error handling, defer statements, goroutines
- **Production Ready**: Proper escaping, error handling, timeout mechanisms
- **Docker Optimized**: Builder pattern separates build from runtime

---

## Testing

Test all three formats
./run.sh # Terminal output
./run.sh --output=csv # CSV generation
Verify outputs
cat baltimore_homicide_analysis.csv
cat baltimore_homicide


---

## References

- **Go Official Docs**: https://go.dev/doc/
- **Docker Multi-stage Builds**: https://docs.docker.com/build/building/multi-stage/
- **Data Source**: chamspage.blogspot.com

---

## Acknowledgments

**Professor Jon White** - Course instruction and project requirements  
**Morgan State University** - Educational support

---

*Last Updated: October 31, 2025*