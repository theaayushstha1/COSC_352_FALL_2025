# Project 6: Baltimore Homicide Analysis in Go

## Overview
This project is a port of Project 5 (Scala implementation) to Go. It analyzes Baltimore homicide data from the Washington Post database, providing statistics on total homicides, case statuses, victim demographics, and temporal patterns.

## Features
- Reads and parses CSV homicide data
- Filters records for Baltimore city
- Analyzes case dispositions (closed vs open)
- Calculates average victim age
- Groups data by year, month, and disposition type
- Outputs results in three formats: stdout (default), CSV, or JSON

## Requirements
- Docker
- Git

## Quick Start

### Setup
```bash
./setup_project6.sh
```

### Run
```bash
# Output to stdout (default)
./run.sh

# Output to CSV
./run.sh csv

# Output to JSON
./run.sh json
```

### Docker Commands
```bash
# Build the Docker image
docker build -t homicide-analysis .

# Run with different output formats
docker run homicide-analysis stdout
docker run homicide-analysis csv
docker run homicide-analysis json

# Copy output files from container
docker run --name homicide-temp homicide-analysis csv
docker cp homicide-temp:/app/output.csv .
docker rm homicide-temp
```

## Project Structure
```
project6/
├── main.go              # Main Go application
├── Dockerfile           # Docker configuration
├── README.md           # This file
├── setup_project6.sh   # Setup script
├── run.sh              # Run script
└── .gitignore          # Git ignore file
```

## Language Comparison: Scala vs Go

### Overview
Both implementations achieve the same functionality but leverage different language paradigms and ecosystems.

### Key Differences

#### 1. **Type System**
**Scala:**
- More flexible type system with type inference
- Case classes provide immutable data structures with pattern matching
- Option type for handling null values elegantly
```scala
case class HomicideRecord(
  uid: String,
  date: LocalDate,
  age: Option[Int]  // Optional value
)
```

**Go:**
- Explicit, static typing with less inference
- Structs are the primary data structure
- Pointers used for optional values
```go
type HomicideRecord struct {
    UID  string
    Date time.Time
    Age  *int  // Pointer for optional value
}
```

#### 2. **Functional vs Imperative Style**
**Scala:**
- Functional programming with immutable collections
- Higher-order functions (map, filter, groupBy)
- More concise syntax
```scala
val baltimoreRecords = records.filter(r => r.city.equalsIgnoreCase("Baltimore"))
val byYear = records.groupBy(_.date.getYear).view.mapValues(_.length)
```

**Go:**
- Imperative style with explicit loops
- No built-in higher-order collection functions
- More verbose but explicit control flow
```go
var baltimoreRecords []HomicideRecord
for _, r := range records {
    if strings.EqualFold(r.City, "Baltimore") {
        baltimoreRecords = append(baltimoreRecords, r)
    }
}
```

#### 3. **Error Handling**
**Scala:**
- Exception-based error handling
- Try/Using for resource management
- Exceptions can be ignored (try-catch)
```scala
Using(Source.fromFile(filename)) { source =>
  // Resource automatically closed
}
```

**Go:**
- Explicit error returns (idiomatic Go)
- defer for resource cleanup
- Forces error checking at every step
```go
file, err := os.Open(filename)
if err != nil {
    return nil, err
}
defer file.Close()
```

#### 4. **Concurrency Model**
**Scala:**
- Built on JVM threading model
- Futures and Actors (Akka) for concurrency
- More complex concurrency primitives

**Go:**
- Goroutines (lightweight threads)
- Channels for communication
- "Don't communicate by sharing memory; share memory by communicating"
- Simpler concurrency model built into the language

#### 5. **Memory Management**
**Scala:**
- JVM garbage collection
- Higher memory overhead
- Automatic memory management

**Go:**
- Garbage collected but more efficient
- Lower memory footprint
- Better control over memory allocation

#### 6. **Compilation & Deployment**
**Scala:**
- Compiles to JVM bytecode
- Requires JVM runtime
- Larger deployment size
- Slower startup time

**Go:**
- Compiles to native machine code
- Single static binary
- No runtime dependencies
- Fast startup, smaller deployment size

#### 7. **Standard Library**
**Scala:**
- Rich collections library
- Leverages entire Java ecosystem
- More built-in functional tools

**Go:**
- Simpler, more focused standard library
- Excellent built-in packages for web, networking, concurrency
- CSV, JSON, HTTP all in standard library

#### 8. **Code Verbosity**
**Scala:** ~150 lines of code (more concise)
**Go:** ~280 lines of code (more explicit)

Scala's functional style and type inference make it more concise, while Go's explicit error handling and imperative loops make it more verbose but clearer.

#### 9. **JSON/CSV Handling**
**Scala:**
- Manual JSON construction using PrintWriter
- CSV parsing with split and manual handling
```scala
writer.println(s"""  "total_homicides": ${analysis("total_homicides")},""")
```

**Go:**
- Built-in encoding/json and encoding/csv packages
- Struct tags for automatic JSON serialization
```go
json.NewEncoder(file).Encode(analysis)
```

#### 10. **Pattern Matching vs Switch**
**Scala:**
- Powerful pattern matching on types, values, structures
```scala
outputFormat.toLowerCase match {
  case "csv" => writeCSV(analysis)
  case "json" => writeJSON(analysis)
  case _ => writeStdout(analysis)
}
```

**Go:**
- Traditional switch statements
- No pattern matching on types
```go
switch strings.ToLower(outputFormat) {
case "csv":
    writeCSV(analysis)
case "json":
    writeJSON(analysis)
default:
    writeStdout(analysis)
}
```

## Go-Specific Features Used

### 1. **Struct Tags for JSON**
Go uses struct tags to control JSON serialization:
```go
type AnalysisResult struct {
    TotalHomicides int `json:"total_homicides"`
    CasesClosed    int `json:"cases_closed"`
}
```

### 2. **Multiple Return Values**
Go functions can return multiple values, idiomatically used for (result, error):
```go
func readHomicideData(filename string) ([]HomicideRecord, error) {
    // ...
    return records, nil
}
```

### 3. **Defer Statement**
Ensures cleanup code runs when function exits:
```go
defer file.Close()
defer writer.Flush()
```

### 4. **Pointer Semantics**
Go uses pointers for optional values and efficient memory usage:
```go
var age *int  // nil means no age
if ageVal, err := strconv.Atoi(ageStr); err == nil {
    age = &ageVal  // Address-of operator
}
```

### 5. **Interface Satisfaction**
Go's csv.NewWriter and json.NewEncoder work with io.Writer interface, allowing flexibility in output destinations.

## Performance Characteristics

| Aspect | Scala | Go |
|--------|-------|-----|
| Startup Time | Slower (JVM) | Fast (native) |
| Memory Usage | Higher | Lower |
| Execution Speed | Fast (JIT) | Very Fast (AOT) |
| Binary Size | Large + JVM | Small (10-20MB) |
| Compilation | Slower | Very Fast |

## When to Use Each Language

### Use Scala When:
- Building complex data processing pipelines
- Leveraging Spark for big data
- Need rich functional programming features
- Working in JVM ecosystem
- Team prefers expressive, concise code

### Use Go When:
- Building microservices or APIs
- Need fast startup and low memory footprint
- Simple deployment requirements (single binary)
- Concurrent/parallel processing is critical
- Team prefers explicit, readable code

## Data Source
The homicide data is sourced from the Washington Post's database:
https://github.com/washingtonpost/data-homicides

## Author
Created for COSC 352 - Fall 2025

## License
Educational use only
