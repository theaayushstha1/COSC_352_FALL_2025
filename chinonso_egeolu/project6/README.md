# Project 6: Baltimore Homicide Analysis in Go

Port of Project 5 from Scala to Go with identical functionality.

## Usage

```bash
./run.sh                    # Console output
./run.sh -output=csv        # Generate CSV files
./run.sh -output=json       # Generate JSON file
```

## Scala vs Go: Key Differences

### Language Type
- **Scala**: Functional + OOP, runs on JVM
- **Go**: Imperative, compiles to native binary

### Data Structures
**Scala:**
```scala
case class Homicide(date: LocalDate, victimAge: Option[Int])
```

**Go:**
```go
type Homicide struct {
    Date      time.Time
    VictimAge *int  // nil = no value
}
```

### Collections
**Scala:** Functional methods like `map`, `filter`, `groupBy`  
**Go:** Simple `for` loops with `range`

### Error Handling
**Scala:** Try/Catch exceptions  
**Go:** Explicit `if err != nil` checks

### JSON Output
**Scala:** Manual string construction  
**Go:** Built-in `encoding/json` with struct tags

### Performance
- **Go:** Faster startup, smaller Docker image (~20MB vs ~500MB)
- **Go:** Single binary, no runtime needed
- **Scala:** Better for complex functional transformations

## Go Features Used
- Structs with JSON tags
- Pointers for optional values
- `defer` for cleanup
- Built-in `flag`, `csv`, `json` packages

## Author

Chinonso Egeolu