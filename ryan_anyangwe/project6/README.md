# Project 6: Baltimore City Homicide Analysis - Golang Implementation

## Student Information
**Name:** Ryan Anyangwe  
**Course:** COSC 352 Fall 2025  
**Date:** October 2025

## Overview
Project 6 is a **complete rewrite** of Project 5 in **Golang (Go)**. The program analyzes Baltimore City homicide statistics and supports three output formats: STDOUT, CSV, and JSON. This README explains the **key differences** between the Scala and Golang implementations.

## How to Run

### Prerequisites
- Docker installed and running
- Git

### Usage

```bash
# Make run.sh executable
chmod +x run.sh

# Default output (stdout)
./run.sh

# CSV output
./run.sh --output=csv

# JSON output
./run.sh --output=json
```

---

# Language Comparison: Scala vs Golang

## 1. Language Paradigm & Philosophy

### Scala
- **Paradigm**: Multi-paradigm (Functional + Object-Oriented)
- **Philosophy**: "Scalable Language" - bridges OOP and FP
- **Typing**: Static with powerful type inference
- **Runs on**: JVM (Java Virtual Machine)
- **Compiled to**: JVM bytecode (.class files)

### Golang
- **Paradigm**: Imperative with some functional features
- **Philosophy**: "Simple, reliable, efficient" - emphasizes simplicity
- **Typing**: Static with lightweight type inference
- **Runs on**: Native (compiles to machine code)
- **Compiled to**: Single native binary executable

**Key Difference**: Scala embraces complexity for expressiveness; Go embraces simplicity for maintainability.

---

## 2. Type System

### Scala Implementation
```scala
case class Homicide(
  number: Int,
  date: String,
  name: String,
  age: Int,
  address: String,
  district: String,
  cause: String,
  cameraPresent: Boolean,
  caseClosed: Boolean
)
```
- **Case classes**: Immutable by default, automatic equals/hashCode/toString
- **Pattern matching**: Powerful destructuring capabilities
- **Type inference**: Very strong, often no type annotations needed

### Golang Implementation
```go
type Homicide struct {
    Number        int
    Date          string
    Name          string
    Age           int
    Address       string
    District      string
    Cause         string
    CameraPresent bool
    CaseClosed    bool
}
```
- **Structs**: Mutable by default, manual method implementations
- **No pattern matching**: Use switch statements and type assertions
- **Type inference**: Limited, mainly with `:=` operator

**Key Difference**: Scala has richer type system with case classes and pattern matching; Go has simpler structs.

---

## 3. Collections & Data Structures

### Scala Implementation
```scala
val homicides = years.flatMap(year => fetchYearData(year))
val districtStats = homicides.groupBy(_.district).map { case (district, cases) =>
  // ...
}.toList.sortBy(_.closureRate)
```
- **Immutable by default**: Collections don't change
- **Rich API**: flatMap, groupBy, map, filter, sortBy built-in
- **Functional style**: Chained transformations
- **Type**: `List[Homicide]`, `Map[String, List[Homicide]]`

### Golang Implementation
```go
var allHomicides []Homicide
for _, year := range years {
    homicides := fetchYearData(year, verbose)
    allHomicides = append(allHomicides, homicides...)
}

districtMap := make(map[string][]Homicide)
for _, h := range homicides {
    districtMap[h.District] = append(districtMap[h.District], h)
}
```
- **Mutable by default**: Slices and maps are modified in place
- **Manual loops**: Explicit `for` loops for transformations
- **Imperative style**: Step-by-step operations
- **Type**: `[]Homicide`, `map[string][]Homicide`

**Key Difference**: Scala favors immutability and functional transformations; Go uses mutable slices with explicit loops.

---

## 4. Error Handling

### Scala Implementation
```scala
Try {
  val connection = new URL(url).openConnection()
  // ... fetch data
} match {
  case Success(data) => data
  case Failure(e) => generateSimulatedData(year)
}
```
- **Try/Success/Failure**: Functional error handling
- **Option[T]**: Represents optional values (Some/None)
- **Either[L, R]**: For computations that can fail

### Golang Implementation
```go
file, err := os.Create("district_analysis.csv")
if err != nil {
    fmt.Printf("Error creating CSV: %v\n", err)
    return
}
defer file.Close()
```
- **Explicit error returns**: Functions return `(result, error)` tuples
- **Check every error**: `if err != nil` pattern everywhere
- **No exceptions**: Errors are values, not exceptions
- **defer**: Ensures cleanup code runs (like finally)

**Key Difference**: Scala uses functional error types; Go uses explicit error values that must be checked.

---

## 5. Concurrency Model

### Scala (not used in this project, but important)
```scala
// Futures for async operations
val future = Future {
  fetchData()
}

// Actors for message-passing
val actor = system.actorOf(Props[MyActor])
actor ! Message
```
- **Futures/Promises**: For asynchronous computations
- **Actors (Akka)**: Message-passing concurrency model
- **Thread-based**: Uses JVM threads

### Golang
```go
// Goroutines - lightweight threads
go fetchData()

// Channels - for communication
ch := make(chan int)
go func() {
    ch <- 42
}()
value := <-ch
```
- **Goroutines**: Extremely lightweight (start with 2KB stack)
- **Channels**: Built-in message passing (`chan` type)
- **CSP Model**: Communicating Sequential Processes
- **"Don't communicate by sharing memory; share memory by communicating"**

**Key Difference**: Go's concurrency is built into the language; Scala relies on libraries (Akka).

---

## 6. Memory Management

### Scala
- **JVM Garbage Collection**: Automatic memory management
- **Heap allocation**: Objects allocated on JVM heap
- **GC pauses**: Can cause stop-the-world pauses
- **Memory overhead**: JVM requires significant memory

### Golang
- **Garbage Collection**: Automatic, but more efficient than JVM
- **Stack allocation**: Escape analysis determines stack vs heap
- **Low-latency GC**: Sub-millisecond pause times
- **Small footprint**: Minimal runtime overhead

**Key Difference**: Both have GC, but Go's is more lightweight and has lower latency.

---

## 7. Compilation & Performance

### Scala
- **Compilation**: Slower (compiles to JVM bytecode)
- **Startup time**: Slow (JVM startup overhead)
- **Runtime performance**: Fast (JIT compilation)
- **Binary size**: Requires JVM (100+ MB)
- **Build time**: Several seconds to minutes

### Golang
- **Compilation**: Very fast (compiles to native code)
- **Startup time**: Instant (native binary)
- **Runtime performance**: Fast (compiled, not JIT)
- **Binary size**: Small standalone executable (~10 MB)
- **Build time**: Sub-second for small programs

**Key Difference**: Go compiles much faster and produces smaller binaries; Scala has JVM warmup time.

---

## 8. Code Structure Comparison

### Function Definitions

**Scala:**
```scala
def fetchYearData(year: Int, verbose: Boolean): List[Homicide] = {
  // implementation
}
```
- Return type after parameter list
- No explicit return keyword needed (last expression)

**Golang:**
```go
func fetchYearData(year int, verbose bool) []Homicide {
    // implementation
    return homicides
}
```
- Return type after function name
- Explicit `return` required
- Multiple return values supported: `func divide(a, b int) (int, error)`

---

### Sorting

**Scala:**
```scala
stats.sortBy(_.closureRate)  // Lambda with placeholder syntax
```

**Golang:**
```go
sort.Slice(stats, func(i, j int) bool {
    return stats[i].ClosureRate < stats[j].ClosureRate
})
```
- Go requires explicit comparison function
- Modifies slice in place

---

### JSON Serialization

**Scala:**
```scala
// Manual JSON string building (no external libraries allowed)
jsonFile.println(s"""  "district": "${stats.district}",""")
```

**Golang:**
```go
// Built-in JSON encoding with struct tags
type DistrictJSON struct {
    District           string  `json:"district"`
    TotalHomicides     int     `json:"total_homicides"`
    ClosureRatePercent float64 `json:"closure_rate_percent"`
}

encoder := json.NewEncoder(file)
encoder.Encode(results)
```
- Go has native JSON support in standard library
- Struct tags control JSON field names

**Key Difference**: Go's standard library is more comprehensive; Scala relies more on external libraries.

---

## 9. Package Management

### Scala
- **SBT (Scala Build Tool)**: Complex build configuration
- **Maven/Ivy**: Dependency resolution
- **build.sbt**: Build definition file
- **Heavy tooling**: Requires understanding of JVM ecosystem

### Golang
- **go.mod**: Simple dependency file
- **go get**: Built-in package manager
- **No external build tools**: Go toolchain handles everything
- **Minimal configuration**: Often zero-config projects

**Key Difference**: Go's tooling is simpler and built-in; Scala requires external build tools.

---

## 10. Interface System

### Scala
```scala
trait Analyzer {
  def analyze(data: List[Homicide]): Stats
}

class DistrictAnalyzer extends Analyzer {
  def analyze(data: List[Homicide]): Stats = { ... }
}
```
- **Traits**: Explicit interface declaration
- **Inheritance**: Classes explicitly extend traits
- **Mixin composition**: Multiple traits can be mixed in

### Golang
```go
type Analyzer interface {
    Analyze(data []Homicide) Stats
}

type DistrictAnalyzer struct {}

func (d DistrictAnalyzer) Analyze(data []Homicide) Stats {
    // implementation
}
```
- **Implicit interfaces**: No explicit "implements" keyword
- **Duck typing**: If it walks like a duck...
- **Composition over inheritance**: Embed structs instead

**Key Difference**: Go has implicit interfaces (structural typing); Scala has explicit interfaces.

---

## 11. Null Safety

### Scala
```scala
val maybeValue: Option[String] = Some("value")
maybeValue match {
  case Some(v) => println(v)
  case None => println("No value")
}
```
- **Option type**: Explicitly represents absence of value
- **No null by default**: Discouraged in idiomatic Scala

### Golang
```go
var value *string  // Can be nil
if value != nil {
    fmt.Println(*value)
}
```
- **Nil pointers**: Any pointer can be nil
- **Manual checking**: Must check for nil explicitly
- **Panic on nil dereference**: Runtime error if not careful

**Key Difference**: Scala's Option type is safer; Go requires manual nil checks.

---

## 12. Standard Library Comparison

### What's Built-in?

**Scala:**
- File I/O: ✅ (java.io)
- JSON: ❌ (need external library)
- CSV: ❌ (need external library)
- HTTP: ✅ (java.net)
- Date/Time: ✅ (java.time)

**Golang:**
- File I/O: ✅ (os, io)
- JSON: ✅ (encoding/json)
- CSV: ✅ (encoding/csv)
- HTTP: ✅ (net/http)
- Date/Time: ✅ (time)

**Key Difference**: Go has more comprehensive standard library; Scala leverages Java libraries.

---

## 13. Project-Specific Differences

### Data Generation

**Scala:**
```scala
(1 to baseCount).map { i =>
  Homicide(...)
}.toList
```
- Functional transformation with map

**Golang:**
```go
homicides := make([]Homicide, baseCount)
for i := 0; i < baseCount; i++ {
    homicides[i] = Homicide{...}
}
```
- Pre-allocated slice with imperative loop

---

### Command-Line Parsing

**Scala:**
```scala
val outputFormat = if (args.length > 0) {
  args(0) match {
    case "csv" => "csv"
    case "json" => "json"
    case _ => "stdout"
  }
} else "stdout"
```
- Manual argument parsing with pattern matching

**Golang:**
```go
import "flag"

outputFormat := flag.String("output", "stdout", "Output format")
flag.Parse()
```
- Built-in `flag` package for command-line parsing

---

### String Formatting

**Scala:**
```scala
println(f"$district%-20s $total%8d ${rate}%14.1f%%")
```
- String interpolation with format specifiers

**Golang:**
```go
fmt.Printf("%-20s %8d %14.1f%%\n", district, total, rate)
```
- Printf-style formatting (C-like)

---

## 14. When to Use Each Language?

### Use Scala When:
- ✅ Building JVM applications (Java interop needed)
- ✅ Complex domain modeling with rich type system
- ✅ Functional programming is priority
- ✅ Data processing (Spark, Kafka integration)
- ✅ Team already familiar with JVM ecosystem

### Use Golang When:
- ✅ Building microservices or APIs
- ✅ High-performance network applications
- ✅ Command-line tools
- ✅ Cloud-native applications (Docker, Kubernetes)
- ✅ Need fast compilation and small binaries
- ✅ Concurrency is important (goroutines)
- ✅ Simplicity and maintainability are priorities

---

## 15. Performance Comparison (This Project)

### Build Time
- **Scala**: ~10-30 seconds (includes SBT overhead)
- **Golang**: ~1-2 seconds

### Binary Size
- **Scala**: N/A (requires JVM, effectively 100+ MB)
- **Golang**: ~10 MB standalone executable

### Startup Time
- **Scala**: ~1-2 seconds (JVM startup)
- **Golang**: Instant (~0.01 seconds)

### Memory Usage
- **Scala**: ~50-100 MB (JVM heap)
- **Golang**: ~5-10 MB

### Execution Speed
- **Both**: Similar for this application (~0.1 seconds)

---

## Quiz Preparation: Key Concepts

### Golang Features You Should Know:

1. **Goroutines**: Lightweight concurrent execution
2. **Channels**: Communication between goroutines
3. **Defer**: Guaranteed cleanup code
4. **Interfaces**: Implicit, structural typing
5. **Error handling**: Explicit error returns
6. **Slice vs Array**: Dynamic vs fixed size
7. **Pointers**: Explicit memory addressing
8. **Struct embedding**: Composition over inheritance
9. **Package system**: Exported (capitalized) vs unexported
10. **go fmt**: Automatic code formatting

### Critical Differences:

| Feature | Scala | Golang |
|---------|-------|--------|
| **Runtime** | JVM | Native |
| **Compilation** | Slow | Fast |
| **Concurrency** | Futures/Actors | Goroutines/Channels |
| **Type System** | Rich | Simple |
| **Null Safety** | Option type | Manual nil checks |
| **Collections** | Immutable default | Mutable default |
| **Error Handling** | Try/Either | Error returns |
| **Standard Library** | Java libs | Comprehensive native |

---

## Conclusion

Both implementations solve the same problem but with different philosophies:

- **Scala**: Emphasizes expressiveness, functional programming, and type safety
- **Golang**: Emphasizes simplicity, performance, and built-in concurrency

The Golang version is:
- ✅ Faster to compile
- ✅ Easier to deploy (single binary)
- ✅ Simpler syntax
- ✅ Better for production microservices

The Scala version is:
- ✅ More expressive
- ✅ Better type safety
- ✅ Richer functional programming features
- ✅ Better for complex domain modeling

**For this specific project** (crime data analysis CLI tool), **Golang is arguably better suited** due to fast compilation, single binary distribution, and simpler deployment.

---

## Files in This Project

```
project6/
├── BaltimoreHomicideAnalysis.go  # Main Go program
├── Dockerfile                     # Go container configuration
├── run.sh                        # Execution script
├── README.md                     # This file
└── .gitignore                    # Git ignore rules
```

## Testing

```bash
# Test all three modes
./run.sh                    # stdout
./run.sh --output=csv       # CSV files
./run.sh --output=json      # JSON file
```

## Contact

For questions:
- GitHub: https://github.com/B3nterprise/COSC_352_FALL_2025

---

**Study this README carefully for the quiz!** The professor may ask about:
- Why Go compiles faster than Scala
- How goroutines differ from JVM threads
- Why Go uses explicit error returns instead of exceptions
- When to choose Go vs Scala for a project