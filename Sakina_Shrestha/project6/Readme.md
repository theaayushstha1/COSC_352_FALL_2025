# Baltimore Homicide Analytics Project — Golang vs. Scala

## Overview

This project ports the original Scala-based Baltimore homicide data scraper and analyzer into Golang, retaining all analytic features (table fetch, parsing, question analytics, and multi-format CSV/JSON output).

## How to Run

1. Build the docker image and run using the supplied `run.sh` script.
2. Supports optional output formats:  
   - `--output=csv` — exports data as CSV
   - `--output=json` — exports data as JSON
   - Defaults to analytics in stdout.

## Major Differences: Scala vs Golang Implementation

| Aspect          | Scala (JVM)                                   | Golang (Native)                            |
|-----------------|-----------------------------------------------|--------------------------------------------|
| Platform        | JVM (requires Scala, Java toolchain)          | Compiled static binary (Go runtime only)   |
| Concurrency     | Actor-model, Futures, powerful concurrency    | Goroutines; built-in lightweight threading |
| Error Handling  | `try/catch`, Option/Maybe, pattern matching   | Explicit error values; no exceptions       |
| Data Modeling   | Case classes, immutability by default         | Struct types, mutability default           |
| I/O             | scala.io, java.io, strong CSV/JSON libraries  | Native CSV/JSON, net/http, stdlib only     |
| Parsing         | Regex, pattern matching, functional style     | Regex, imperative, structs                 |
| Dependency      | JVM, Scala runtime libraries                  | None; just Go standard library             |
| Docker Image    | Large: JVM + Scala toolchain                  | Small: Golang Alpine, compiled binary      |
| Build/Start     | Scala compile, main entry worked via JVM      | `go build`; runs as self-contained binary  |
| Ecosystem       | Rich library support (Akka, Spark, etc.)      | Simpler, “batteries-included” stdlib       |

### Key Golang Features

- Simple syntax, fast compilation
- Direct error handling with explicit values
- Native concurrency using goroutines and channels
- Strong, explicit typing, easier cross-compilation
- Binary distribution—no dependency on JVM

### Why Port?

Porting to Go offers easier containerization, smaller image sizes, and improved startup performance while preserving all algorithm logic and analytics.

## Usage Example
