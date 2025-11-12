# Project 6: Baltimore Crime Analysis - Golang Implementation

## Overview
This project is a Golang port of Project 5's Baltimore crime analysis. It analyzes Baltimore Police Department Part 1 Crime Data and generates statistics by neighborhood with support for multiple output formats (stdout, CSV, JSON).

## Usage

### Default Output (stdout)
```bash
./run.sh
```

### CSV Output
```bash
./run.sh --output=csv
```

### JSON Output
```bash
./run.sh --output=json
```

## File Structure
```
project6/
├── main.go          # Main Go source code
├── go.mod           # Go module definition
├── Dockerfile       # Docker container configuration
├── run.sh           # Execution script
└── README.md        # This file
```

---

## Scala vs Golang: Key Differences

### 1. **Language Paradigm**

#### Scala
- **Multi-paradigm**: Functional + Object-Oriented
- Encourages immutability and functional programming patterns
- Runs on the JVM (Java Virtual Machine)
- Example:
```scala
val statsData = crimeStats.as[CrimeStats].collect()
statsData.foreach { stat => println(stat) }
```

#### Golang
- **Imperative/Procedural** with some OOP features
- Emphasizes simplicity and readability
- Compiled to native machine code
- Example:
```go
for _, stat := range stats {
    fmt.Println(stat)
}
```

**Key Difference**: Scala treats functions as first-class citizens with rich functional operators (map, filter, fold), while Go uses simple for loops and explicit iteration.

---

### 2. **Type System**

#### Scala
- **Strong static typing** with powerful type inference
- Advanced features: pattern matching, implicit conversions, type classes
- Example:
```scala
case class CrimeStats(
  neighborhood: String,
  totalCrimes: Long,
  violentCrimes: Long,
  propertyCrimes: Long,
  averagePerMonth: Double
)
```

#### Golang
- **Strong static typing** with simpler type system
- Struct tags for JSON/CSV serialization
- No inheritance, uses composition and interfaces
- Example:
```go
type CrimeStats struct {
    Neighborhood    string  `json:"neighborhood"`
    TotalCrimes     int     `json:"total_crimes"`
    ViolentCrimes   int     `json:"violent_crimes"`
    PropertyCrimes  int     `json:"property_crimes"`
    AveragePerMonth float64 `json:"average_per_month"`
}
```

**Key Difference**: Scala has more expressive types and pattern matching. Go uses struct tags for metadata instead of runtime reflection.

---

### 3. **Data Processing Approach**

#### Scala (with Apache Spark)
- **Distributed data processing** framework
- Lazy evaluation and query optimization
- DataFrame API for SQL-like operations
- Example:
```scala
val crimeStats = crimesDF
  .filter($"Neighborhood".isNotNull)
  .groupBy("Neighborhood")
  .agg(count("*").as("totalCrimes"))
  .orderBy($"totalCrimes".desc)
```

#### Golang
- **In-memory sequential processing**
- Explicit loops and aggregation
- Manual map/reduce patterns
- Example:
```go
statsMap := make(map[string]*CrimeStats)
for _, record := range records {
    stats, exists := statsMap[record.Neighborhood]
    if !exists {
        stats = &CrimeStats{Neighborhood: record.Neighborhood}
        statsMap[record.Neighborhood] = stats
    }
    stats.TotalCrimes++
}
```

**Key Difference**: Scala/Spark is designed for big data and can scale across clusters. Go processes data in a single process but is much simpler and faster for small-to-medium datasets.

---

### 4. **Concurrency Model**

#### Scala
- Uses **thread-based concurrency** (JVM threads)
- Futures, Promises, and Akka actors for async programming
- Higher overhead per thread
- Example:
```scala
import scala.concurrent.Future
Future {
  // Async work
}
```

#### Golang
- **Goroutines**: lightweight threads (multiplexed onto OS threads)
- Channels for communication between goroutines
- "Don't communicate by sharing memory; share memory by communicating"
- Example:
```go
go func() {
    // Concurrent work
}()
```

**Key Difference**: Go's goroutines are much more lightweight (~2KB stack) compared to JVM threads (~1MB stack), making Go excellent for high-concurrency applications.

---

### 5. **Memory Management**

#### Scala
- **JVM Garbage Collection** (GC)
- Automatic memory management
- GC pauses can affect performance
- Heap-based allocation

#### Golang
- **Efficient Garbage Collection** with low latency
- Escape analysis determines stack vs heap allocation
- More predictable GC pauses
- Explicit pointer management

**Key Difference**: Go's GC is optimized for low-latency applications (sub-millisecond pauses), while JVM GC can have longer pause times but handles larger heaps better.

---

### 6. **Error Handling**

#### Scala
- **Exceptions** for error handling
- Try/Success/Failure for functional error handling
- Can throw and catch exceptions
- Example:
```scala
try {
  // risky operation
} catch {
  case e: Exception => println(e)
}
```

#### Golang
- **Explicit error returns** (no exceptions)
- Functions return `(value, error)` tuples
- Forces developers to handle errors explicitly
- Example:
```go
file, err := os.Open(filename)
if err != nil {
    return nil, err
}
defer file.Close()
```

**Key Difference**: Go's error handling is more verbose but makes error paths explicit. Scala's exceptions can hide error flows.

---

### 7. **Standard Library**

#### Scala
- **Relies heavily on external libraries** (Spark, Akka, Play)
- Rich collection library
- Smaller standard library

#### Golang
- **"Batteries included" philosophy**
- Extensive standard library: HTTP servers, JSON, CSV, networking, crypto
- Minimal external dependencies needed
- Example packages: `encoding/csv`, `encoding/json`, `net/http`

**Key Difference**: Go programs often have zero external dependencies, while Scala projects typically depend on many libraries.

---

### 8. **Compilation and Deployment**

#### Scala
- **Compiles to JVM bytecode**
- Requires JVM to run
- Slower startup times
- Larger deployment size (includes JVM)
- Cross-platform via JVM

#### Golang
- **Compiles to native machine code**
- Single static binary (no runtime dependencies)
- Fast startup times
- Small deployment size
- Cross-compilation built-in
```bash
GOOS=linux GOARCH=amd64 go build
```

**Key Difference**: Go produces standalone executables, while Scala requires a JVM installation.

---

### 9. **Performance Comparison**

#### Scala/Spark
- **Pros**: Excellent for distributed processing, handles massive datasets
- **Cons**: Higher memory usage, slower startup, JVM warmup time
- Best for: Big data analytics, ETL pipelines

#### Golang
- **Pros**: Fast execution, low memory footprint, quick startup
- **Cons**: Not designed for distributed processing out-of-the-box
- Best for: Microservices, CLI tools, system programming

**For this project**: Go is faster for small-to-medium CSV files. Spark would excel with multi-gigabyte datasets across a cluster.

---

### 10. **Code Simplicity**

#### Scala
- More expressive and concise
- Steeper learning curve
- Many ways to solve the same problem
- Example (filter and map in one line):
```scala
crimes.filter(_.neighborhood != "").map(processRecord)
```

#### Golang
- Simple and explicit
- Easier to learn
- "One obvious way" philosophy
- Example (explicit loop):
```go
for _, crime := range crimes {
    if crime.Neighborhood != "" {
        processRecord(crime)
    }
}
```

**Key Difference**: Scala favors expressiveness, Go favors simplicity and readability.

---

## Golang-Specific Features Used in This Project

### 1. **Structs and Struct Tags**
```go
type CrimeStats struct {
    Neighborhood    string  `json:"neighborhood"`
    TotalCrimes     int     `json:"total_crimes"`
}
```
Struct tags provide metadata for encoding/decoding (JSON, CSV, etc.).

### 2. **Flag Package for CLI Arguments**
```go
outputFormat := flag.String("output", "stdout", "Output format")
flag.Parse()
```
Built-in command-line flag parsing.

### 3. **Maps for Aggregation**
```go
statsMap := make(map[string]*CrimeStats)
```
Native hash maps for O(1) lookups and efficient aggregation.

### 4. **Defer for Resource Cleanup**
```go
defer file.Close()
```
Ensures resources are cleaned up even if errors occur.

### 5. **Multiple Return Values**
```go
func readData() ([]Record, error) {
    // ...
    return records, nil
}
```
Idiomatic error handling without exceptions.

### 6. **Interfaces for Polymorphism**
Go uses implicit interfaces - any type that implements the required methods satisfies the interface without explicit declaration.

### 7. **Slices (Dynamic Arrays)**
```go
records := make([]CrimeRecord, 0, 100)
records = append(records, newRecord)
```
Dynamic arrays with automatic growth.

### 8. **CSV and JSON Encoding**
Standard library provides robust CSV/JSON support:
```go
encoder := json.NewEncoder(file)
encoder.SetIndent("", "  ")
```

---

## When to Use Each Language

### Use Scala/Spark when:
- Processing **terabytes** of data
- Need distributed computing across a cluster
- Complex ETL pipelines
- Real-time streaming analytics
- Team familiar with functional programming

### Use Golang when:
- Building **microservices** or APIs
- Need fast compilation and deployment
- Command-line tools
- System programming
- Network services (web servers, proxies)
- Containerized applications
- Small-to-medium data processing

---

## Quiz Preparation: Key Points

1. **Go's Goroutines** vs Scala's thread-based concurrency
2. **Static compilation** (Go) vs JVM bytecode (Scala)
3. **Explicit error handling** (Go) vs Exceptions (Scala)
4. **Spark's distributed processing** vs Go's in-memory processing
5. **Go's simple type system** vs Scala's advanced type features
6. **Standard library richness** in Go
7. **Deployment simplicity**: Go's single binary vs Scala's JVM requirement
8. **Performance characteristics**: Go's fast startup vs Spark's scalability
9. **Code philosophy**: Go's simplicity vs Scala's expressiveness
10. **When to choose each**: Dataset size and application requirements

---

## Building and Running

### Local Development
```bash
# Build
go build -o baltimore-analysis main.go

# Run with different formats
./baltimore-analysis
./baltimore-analysis -output=csv
./baltimore-analysis -output=json
```

### Docker
```bash
# Build image
docker build -t baltimore-analysis-go .

# Run
docker run --rm baltimore-analysis-go
docker run --rm baltimore-analysis-go -output=csv
```

### Using run.sh Script
```bash
chmod +x run.sh
./run.sh
./run.sh --output=csv
./run.sh --output=json
```

---

## Dependencies
- **Golang 1.21+**
- **Docker** (for containerization)
- **Baltimore PD Crime Data** (downloaded automatically)

## Author
[Your Name]  
COSC 352 - Fall 2025  
Project 6: Golang Implementation
