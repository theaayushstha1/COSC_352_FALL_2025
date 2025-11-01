# Project 6: Baltimore Homicide Analysis in Golang

## Overview
This project ports the Scala implementation from Project 5 to Golang, maintaining the same functionality while demonstrating the differences between the two languages.

## Functionality
The program analyzes Baltimore homicide data and provides three output formats:
- **stdout** (default): Human-readable console output
- **CSV**: Structured data output (`--output=csv`)
- **JSON**: Machine-readable format (`--output=json`)

## Research Questions
1. How many victims were under 18 years old?
2. How many homicide cases are open vs closed vs unknown?

## Usage
```bash
# Default stdout output
./run.sh

# CSV output
./run.sh --output=csv

# JSON output
./run.sh --output=json
```

## Key Differences Between Scala and Golang

### 1. **Language Paradigm**
- **Scala**: Multi-paradigm (functional + object-oriented). Encourages immutable data and functional programming with features like pattern matching, higher-order functions, and collections operations.
- **Golang**: Imperative and procedural. Focuses on simplicity and explicit code with minimal abstractions.

### 2. **Type System**
- **Scala**: Statically typed with powerful type inference. Supports complex types, generics, and implicit conversions.
- **Golang**: Statically typed with limited type inference. No generics (until Go 1.18+), uses interfaces for polymorphism.

### 3. **Syntax and Verbosity**
- **Scala**: More concise. Can express operations in fewer lines using functional constructs.
```scala
  val under18 = homicides.count(h => h.victimAge.toIntOption.exists(_ < 18))
```
- **Golang**: More verbose and explicit. Requires more boilerplate code.
```go
  for _, h := range homicides {
      age, err := strconv.Atoi(h.Age)
      if err == nil && age < 18 {
          result.VictimsUnder18++
      }
  }
```

### 4. **Error Handling**
- **Scala**: Uses `Option`, `Try`, `Either` types for functional error handling. Exceptions are available but discouraged.
- **Golang**: Explicit error returns. Functions return `(value, error)` tuples. Requires checking `if err != nil` throughout.

### 5. **Collections and Data Processing**
- **Scala**: Rich collections library with functional operations (map, filter, fold, etc.). Immutable by default.
```scala
  homicides.filter(_.victimAge.toIntOption.exists(_ < 18)).length
```
- **Golang**: Basic arrays and slices. Manual iteration with for loops. Mutable by default.
```go
  for _, h := range homicides { /* manual filtering */ }
```

### 6. **Struct vs Case Class**
- **Scala**: Case classes provide automatic equality, toString, pattern matching, and immutability.
- **Golang**: Structs are simple data containers. No automatic methods, manual equality checks needed.

### 7. **Concurrency Model**
- **Scala**: Uses actors (Akka) or futures/promises for async operations. Built on JVM threads.
- **Golang**: Goroutines and channels. Lightweight concurrency is a core language feature with `go` keyword.

### 8. **Compilation and Runtime**
- **Scala**: Compiles to JVM bytecode. Runs on Java Virtual Machine. Slower startup, but optimized over time.
- **Golang**: Compiles to native machine code. Single binary with no runtime dependencies. Fast startup and execution.

### 9. **Memory Management**
- **Scala**: JVM garbage collection. Automatic memory management with GC pauses.
- **Golang**: Garbage collection with lower latency. Designed for faster GC cycles.

### 10. **Package Management**
- **Scala**: SBT (Scala Build Tool) or Maven. Complex build definitions.
- **Golang**: Go modules (`go.mod`). Simple dependency management with `go get`.

## Golang-Specific Features Used in This Project

### 1. **Structs with Tags**
```go
type AnalysisResult struct {
    VictimsUnder18 int `json:"victims_under_18"`
    ClosedCases    int `json:"closed_cases"`
}
```
Tags provide metadata for encoding/decoding (JSON field names).

### 2. **Multiple Return Values**
```go
func readCSV(filename string) ([]Homicide, error) {
    // Returns both data and error
}
```
Common pattern in Go for error handling.

### 3. **Defer Statement**
```go
defer file.Close()
```
Ensures cleanup code runs when function exits, regardless of return path.

### 4. **Package Organization**
- `package main`: Executable program
- Import standard library packages: `encoding/csv`, `encoding/json`, `fmt`, `os`, etc.

### 5. **Explicit Error Checking**
Every operation that can fail returns an error:
```go
if err != nil {
    fmt.Printf("Error: %v\n", err)
    return
}
```

### 6. **String Manipulation**
- `strings.HasPrefix()`: Check string prefixes
- `strings.TrimPrefix()`: Remove prefix
- `strings.ToLower()`: Case conversion
- `strings.TrimSpace()`: Whitespace removal

### 7. **Type Conversion**
```go
age, err := strconv.Atoi(h.Age)  // String to integer
strconv.Itoa(result.TotalCases)   // Integer to string
```

## Why Golang?

**Advantages:**
- **Simplicity**: Easy to learn, read, and maintain
- **Performance**: Compiled to native code, fast execution
- **Concurrency**: Built-in goroutines for parallel processing
- **Deployment**: Single binary, no runtime dependencies
- **Tooling**: Excellent standard library and built-in formatting/testing

**Trade-offs:**
- More verbose than Scala
- Less expressive type system
- Fewer abstractions and functional programming features

## Docker Implementation
Uses official Golang Alpine image for minimal container size:
```dockerfile
FROM golang:1.21-alpine
```

The multi-stage build compiles the Go code and creates a lightweight executable.

## Files
- `main.go`: Go source code
- `homicides.csv`: Baltimore homicide data
- `Dockerfile`: Container definition
- `run.sh`: Build and execution script
- `README.md`: This documentation

## Conclusion
Both Scala and Golang can accomplish the same task, but with different philosophies:
- **Scala**: Powerful abstractions, functional elegance, JVM ecosystem
- **Golang**: Simplicity, explicit code, performance, easy deployment

The choice depends on project requirements: Scala for complex data processing and functional patterns, Golang for straightforward services and system programming.