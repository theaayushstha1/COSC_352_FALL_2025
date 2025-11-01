# Baltimore Homicide Analysis - Project 6: Golang Implementation

## Overview
This project ports the Baltimore homicide analysis from Scala (Project 5) to Golang, maintaining the same functionality while leveraging Go's native features and idioms. The program analyzes Baltimore City homicide statistics and outputs results in three formats: stdout, CSV, or JSON.

## Author
Your Name - Project 6 Submission

## Key Differences: Scala vs Golang

### 1. **Language Paradigm**

#### Scala (Functional + Object-Oriented)
```scala
// Functional approach with immutability
val weekendHomicides = homicides.filter { h =>
  val dayOfWeek = h.date.getDayOfWeek.getValue
  dayOfWeek >= 6
}

// Case classes are immutable by default
case class Homicide(date: LocalDate, time: String, ...)
```

#### Golang (Imperative + Procedural)
```go
// Imperative approach with explicit loops
var weekendHomicides []Homicide
for _, h := range homicides {
    if h.Date.Weekday() == time.Saturday || h.Date.Weekday() == time.Sunday {
        weekendHomicides = append(weekendHomicides, h)
    }
}

// Structs are mutable; immutability must be enforced manually
type Homicide struct {
    Date time.Time
    Time string
    // ...
}
```

**Key Insight:** Scala encourages functional programming with built-in immutability, while Go favors explicit, imperative code that's easier to understand but requires more manual control.

---

### 2. **Type System**

#### Scala (Rich Type System)
```scala
// Option types for null safety
age: Option[Int]  // Explicit handling of missing values

// Pattern matching on types
result match {
  case Success(data) => data
  case Failure(e) => handleError(e)
}
```

#### Golang (Simple Type System)
```go
// Pointers for nullable values
Age *int  // nil represents absence

// Multiple return values for error handling
data, err := fetchData()
if err != nil {
    handleError(err)
}
```

**Key Insight:** Scala has a more sophisticated type system with algebraic data types (Option, Either, Try), while Go uses pointers and multiple return values for a simpler, more explicit approach.

---

### 3. **Error Handling**

#### Scala (Exception-Based with Try/Success/Failure)
```scala
def fetchData(): Try[List[Homicide]] = Try {
  // Code that might fail
}

fetchData() match {
  case Success(data) => processData(data)
  case Failure(e) => println(s"Error: ${e.getMessage}")
}
```

#### Golang (Explicit Error Returns)
```go
func fetchData() ([]Homicide, error) {
    // Code that might fail
    if err != nil {
        return nil, err
    }
    return data, nil
}

data, err := fetchData()
if err != nil {
    fmt.Printf("Error: %v\n", err)
}
```

**Key Insight:** Scala treats errors as values (Try monad), while Go uses explicit error returns that must be checked at each call site. Go's approach is more verbose but makes error paths explicit.

---

### 4. **Collections and Data Manipulation**

#### Scala (Rich Collections API)
```scala
// Functional transformations
val districtStats = byDistrict.map { case (district, cases) =>
  val closed = cases.count(_.disposition.contains("closed"))
  val clearanceRate = (closed * 100.0) / cases.length
  DistrictStats(district, cases.length, closed, ...)
}.toList.sortBy(-_.clearanceRate)
```

#### Golang (Explicit Loops)
```go
// Manual iteration and transformation
var districtStats []DistrictStats
for district, cases := range byDistrict {
    closed := 0
    for _, h := range cases {
        if strings.Contains(h.Disposition, "closed") {
            closed++
        }
    }
    clearanceRate := float64(closed) * 100.0 / float64(len(cases))
    districtStats = append(districtStats, DistrictStats{...})
}

// Manual sorting
sort.Slice(districtStats, func(i, j int) bool {
    return districtStats[i].ClearanceRate > districtStats[j].ClearanceRate
})
```

**Key Insight:** Scala provides high-level collection operations (map, filter, reduce) built-in, while Go requires explicit loops and sorting logic. Go code is more verbose but arguably easier to debug.

---

### 5. **Compilation and Performance**

#### Scala
- **JVM-based**: Compiles to bytecode, runs on Java Virtual Machine
- **Startup time**: Slower due to JVM initialization (~1-2 seconds)
- **Runtime performance**: Very fast after JVM warm-up (JIT compilation)
- **Memory**: Higher baseline memory usage (JVM overhead)
- **Docker image size**: ~500MB (includes JVM)

#### Golang
- **Native compilation**: Compiles directly to machine code
- **Startup time**: Near-instant (<0.1 seconds)
- **Runtime performance**: Consistently fast, no warm-up needed
- **Memory**: Low memory footprint
- **Docker image size**: ~10-20MB (multi-stage build with Alpine)

**Key Insight:** Go produces smaller, faster-starting binaries ideal for containers and microservices. Scala's JVM provides better peak performance for long-running applications.

---

### 6. **Concurrency Model**

#### Scala (Futures and Actors)
```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

val future1 = Future { analyzeWeekend(data) }
val future2 = Future { analyzeDistricts(data) }

for {
  result1 <- future1
  result2 <- future2
} yield CombinedResult(result1, result2)
```

#### Golang (Goroutines and Channels)
```go
// Goroutines are lightweight threads
ch1 := make(chan WeekendResult)
ch2 := make(chan DistrictResult)

go func() {
    ch1 <- analyzeWeekend(data)
}()

go func() {
    ch2 <- analyzeDistricts(data)
}()

result1 := <-ch1
result2 := <-ch2
```

**Key Insight:** Go's goroutines are built into the language and extremely lightweight (thousands can run concurrently). Scala uses Futures/Promises or Akka actors, which are more sophisticated but require libraries.

---

### 7. **JSON Serialization**

#### Scala (Manual JSON Construction)
```scala
def outputJSON(...): Unit = {
  writer.println("{")
  writer.println("  \"metadata\": {")
  writer.println(s"    \"analysisDate\": \"$date\",")
  // ... manual string building
  writer.println("}")
}
```

#### Golang (Struct Tags + Encoding Package)
```go
type Metadata struct {
    AnalysisDate string `json:"analysisDate"`
    TotalRecords int    `json:"totalRecords"`
}

func outputJSON(...) {
    output := AnalysisOutput{
        Metadata: Metadata{...},
        Question1: Question1Output{...},
    }
    
    jsonData, _ := json.MarshalIndent(output, "", "  ")
    os.WriteFile(path, jsonData, 0644)
}
```

**Key Insight:** Go's struct tags enable automatic JSON serialization/deserialization with reflection. Scala requires manual JSON construction or external libraries (Play JSON, Circe).

---

### 8. **Memory Management**

#### Scala
- **Garbage Collection**: JVM's sophisticated generational GC
- **Heap management**: Automatic, tunable with JVM flags
- **No manual memory management needed**

#### Golang
- **Garbage Collection**: Concurrent, low-latency GC optimized for modern apps
- **Stack allocation**: Go compiler allocates on stack when possible (escape analysis)
- **Better control**: Can optimize memory layout with struct packing

**Key Insight:** Both languages have garbage collection, but Go's GC is designed for low latency (sub-millisecond pauses), while JVM's GC is optimized for throughput.

---

### 9. **Dependency Management**

#### Scala
- **Build tool**: SBT (Scala Build Tool) or Maven
- **Dependencies**: Declared in `build.sbt`
- **Ecosystem**: Rich JVM ecosystem (can use Java libraries)

#### Golang
- **Built-in**: `go mod` is built into the language
- **Dependencies**: Declared in `go.mod` file
- **Standard library**: Extensive, reduces need for external dependencies

**Key Insight:** Go's standard library is comprehensive enough that this project requires **zero external dependencies**. Scala often requires libraries for common tasks (JSON parsing, CSV handling).

---

### 10. **Code Size and Verbosity**

#### Scala Version
- **Lines of code**: ~450 lines
- **Conciseness**: Functional style reduces boilerplate
- **Expressiveness**: Type inference and higher-order functions

#### Golang Version
- **Lines of code**: ~650 lines
- **Verbosity**: More explicit loops and error checking
- **Clarity**: Each step is explicit and obvious

**Key Insight:** Scala is more concise but requires understanding functional concepts. Go is more verbose but arguably easier for newcomers to understand.

---

## Golang-Specific Features Demonstrated

### 1. **Struct Tags for JSON**
```go
type DistrictStats struct {
    District      string  `json:"district"`
    Total         int     `json:"totalCases"`
    ClearanceRate float64 `json:"clearanceRate"`
}
```
Struct tags provide metadata for serialization without code changes.

### 2. **Multiple Return Values**
```go
func analyzeData() (WeekendResult, DistrictResult) {
    return weekendResult, districtResult
}
```
Allows returning multiple values without wrapper objects.

### 3. **Defer for Resource Cleanup**
```go
file, _ := os.Create("output.csv")
defer file.Close()  // Guaranteed to run when function exits
```
Ensures resources are cleaned up, even if errors occur.

### 4. **Interfaces and Duck Typing**
```go
// Any type with Write() method satisfies io.Writer
func processOutput(w io.Writer) {
    w.Write([]byte("data"))
}
```
Implicit interface satisfaction enables powerful abstractions.

### 5. **Slices (Dynamic Arrays)**
```go
homicides := make([]Homicide, 0, 550)  // Pre-allocate capacity
homicides = append(homicides, newRecord)
```
Built-in dynamic arrays with efficient growth.

### 6. **Package System**
```go
package main  // Entry point package
import (
    "fmt"     // Standard library
    "time"    // No external dependencies needed
)
```
Simple, flat package structure with no circular dependencies allowed.

### 7. **Time Package**
```go
now := time.Now()
threeYearsAgo := now.AddDate(-3, 0, 0)
if record.Date.After(threeYearsAgo) {
    // Process recent data
}
```
Rich standard library for time manipulation.

---

## Project Structure
```
project6/
├── main.go        # Complete Go implementation (single file)
├── Dockerfile     # Multi-stage Docker build
├── run.sh         # Execution script
└── README.md      # This file
```

**Note:** Unlike Scala which needs multiple files or classes, Go's simplicity allows the entire application in one file.

---

## Usage

### Prerequisites
- Docker installed and running
- Bash shell

### Quick Start

```bash
# Navigate to project directory
cd project6

# Make script executable
chmod +x run.sh

# Run with stdout (default)
./run.sh

# Generate CSV output
./run.sh --output=csv

# Generate JSON output
./run.sh --output=json
```

### Docker Build Process

The Golang version uses a **multi-stage build**:

1. **Builder stage**: Compiles Go code in full golang:1.21-alpine image
2. **Final stage**: Copies only the binary to minimal alpine:latest image

Result: **~15MB** final image vs **~500MB** for Scala

---

## Performance Comparison

| Metric | Scala | Golang |
|--------|-------|--------|
| Docker Image Size | ~500 MB | ~15 MB |
| First Startup Time | ~2-3 seconds | ~0.1 seconds |
| Subsequent Runs | ~2-3 seconds | ~0.1 seconds |
| Memory Usage | ~150-200 MB | ~10-20 MB |
| Compilation Time | ~10-15 seconds | ~2-3 seconds |

---

## When to Use Which Language?

### Choose Scala When:
- Building complex data processing pipelines
- Need functional programming paradigms
- Working with Apache Spark, Kafka, or Akka
- Long-running applications where JVM warm-up pays off
- Team has strong functional programming experience

### Choose Golang When:
- Building microservices or cloud-native apps
- Need fast startup times (serverless, containers)
- Want simple deployment (single binary)
- Team prefers explicit, readable code
- Performance-critical low-latency systems
- Building CLI tools or system utilities

---

## Quiz Preparation: Key Concepts

### Golang Fundamentals

1. **What is a goroutine?**
   - Lightweight thread managed by Go runtime
   - Can spawn thousands concurrently
   - Communicate via channels

2. **What is a channel?**
   - Typed conduit for communication between goroutines
   - Enables safe concurrent data sharing
   - Can be buffered or unbuffered

3. **What is defer?**
   - Schedules function call to run after surrounding function returns
   - Used for cleanup (closing files, unlocking mutexes)
   - Executes in LIFO order if multiple defers

4. **What is an interface?**
   - Set of method signatures
   - Implicitly satisfied (duck typing)
   - Enables polymorphism without inheritance

5. **What are struct tags?**
   - Metadata attached to struct fields
   - Used by reflection for serialization/validation
   - Format: `json:"fieldName" xml:"fieldName"`

### Comparison Questions

1. **How does error handling differ?**
   - Scala: Exceptions + Try/Success/Failure monads
   - Go: Multiple return values with explicit error checks

2. **How does concurrency differ?**
   - Scala: Futures/Promises or Akka actors
   - Go: Built-in goroutines and channels

3. **How does type safety compare?**
   - Scala: Richer type system (Option, Either, pattern matching)
   - Go: Simpler types (pointers for null, multiple returns for errors)

4. **How does compilation differ?**
   - Scala: Compiles to JVM bytecode, runs on JVM
   - Go: Compiles to native machine code, no runtime needed

5. **Which has better performance?**
   - Depends on use case:
     - Startup: Go wins (instant)
     - Peak throughput: Scala/JVM (after warm-up)
     - Memory: Go uses less
     - Container size: Go much smaller

---

## Common Pitfalls and Solutions

### Go-Specific Gotchas

1. **Slice Capacity vs Length**
```go
// Wrong: Creates slice of length 550 with zero values
homicides := make([]Homicide, 550)

// Right: Creates empty slice with capacity for 550
homicides := make([]Homicide, 0, 550)
```

2. **Range Loop Variable Reuse**
```go
// Wrong: All pointers reference same variable
for _, h := range homicides {
    weekend = append(weekend, &h)  // BUG!
}

// Right: Create new variable or use index
for i := range homicides {
    weekend = append(weekend, &homicides[i])
}
```

3. **Map Iteration Order**
```go
// Maps have undefined iteration order
// Use sorted keys if order matters
keys := make([]string, 0, len(myMap))
for k := range myMap {
    keys = append(keys, k)
}
sort.Strings(keys)
```

---

## Testing Your Understanding

### Practical Exercises

1. **Modify the code to use goroutines** for parallel analysis of Questions 1 and 2
2. **Add a new output format** (XML) using struct tags
3. **Implement caching** using a map with mutex for thread safety
4. **Add command-line validation** using the `flag` package properly

---

## Conclusion

Both Scala and Golang are excellent languages with different philosophies:

- **Scala**: Powerful, expressive, functional - for complex business logic
- **Golang**: Simple, fast, pragmatic - for cloud infrastructure

This project demonstrates that the same problem can be solved effectively in both languages, but the approaches and trade-offs differ significantly. Understanding these differences makes you a better polyglot programmer.

---

## Additional Resources

- [Official Go Documentation](https://go.dev/doc/)
- [Effective Go](https://go.dev/doc/effective_go)
- [Go by Example](https://gobyexample.com/)
- [A Tour of Go](https://go.dev/tour/)
