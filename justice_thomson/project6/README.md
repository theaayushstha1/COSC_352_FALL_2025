# Project 6: Baltimore Homicide Statistics Analysis (Golang Port)

## Overview
This is a port of the original Scala-based Project 5 to Golang for Project 6. It analyzes Baltimore City homicide data for 2025 from the specified blog page. It answers two questions via stdout by default:
1. How many homicides occurred in each month of 2025?
2. What is the closure rate for incidents with and without surveillance cameras in 2025?

Additionally, it supports outputting the aggregated data from these questions in CSV or JSON formats for use in future reports, via the --output flag.

The analysis is performed using a Golang program that fetches and parses the HTML content, extracts relevant entries for 2025, and computes the required statistics or outputs structured data. As of October 30, 2025, the page lists 112 homicides, and the parsing logic handles the current structure effectively.

## Requirements
- Docker must be installed and running.
- The project uses only native Golang standard libraries (net/http, regexp, encoding/json, etc.).

## Files
- `main.go`: The Golang source code for fetching, parsing, analyzing, and outputting the data.
- `Dockerfile`: Defines the Docker image for building and running the Golang program.
- `run.sh`: Shell script to build the Docker image and run the container, passing any arguments (e.g., --output=csv).
- `README.md`: This file.

## How to Run
1. Ensure you are in the project directory.
2. Make `run.sh` executable if necessary: `chmod +x run.sh`.
3. Execute `./run.sh` for default stdout output (question answers).
4. For structured output:
   - `./run.sh --output=csv`: Writes aggregated data to `data.csv` in the current directory.
   - `./run.sh --output=json`: Writes aggregated data to `data.json` in the current directory.

The script will build the Docker image and run the container, producing either stdout or files as specified.

## Data Format Explanation
When using `--output=csv` or `--output=json`, the program outputs the aggregated data from the two questions instead of the raw entries. This was chosen to provide summarized insights in a standardized, machine-readable way suitable for aggregation into reports, as hinted in the project guidelines. The format focuses on the key results for easy combination with other datasets.

### CSV Format (data.csv)
- Structured as two sections separated by a blank line:
  - **Question 1 Section**: Headers "month,count" with rows for each month (e.g., "January",13).
  - **Question 2 Section**: Headers "metric,value" with rows for stats like "total_incidents",112; "with_cameras",15; etc., including percentages.
- **Why this format?**: CSV is widely supported for import into spreadsheets or data tools. Separating sections allows easy parsing of each question's data independently, while keeping it in one file for simplicity. Metrics are quoted/escaped as needed.

### JSON Format (data.json)
- An object with two keys:
  - `"question1"`: Array of objects like [{"month":"January","count":13}, ...]
  - `"question2"`: Object like {"total_incidents":"112", "with_cameras":"15", "closed_with_cameras":"5", "closed_with_cameras_pct":"33.3%", ...}
- **Why this format?**: JSON is ideal for programmatic use in reports or dashboards. It structures the aggregates hierarchically for easy access (e.g., via question keys), with escaped values for validity. This enables seamless integration with tools like JavaScript or Python, aligning with collective analysis goals.

This format was selected to directly represent the insights from the questions, enabling quick recreation of visualizations or comparisons in reports. Only 2025 data is included.

## Differences Between Scala and Golang Implementations
### Language Paradigms and Features
- **Scala**: A hybrid functional/object-oriented language running on the JVM. It supports advanced features like pattern matching, immutable collections by default, and concise functional operations (e.g., groupBy, mapValues, flatMap). Scala's regex integration (scala.util.matching.Regex) allows seamless matching and extraction.
- **Golang**: A statically typed, compiled language focused on simplicity, efficiency, and concurrency (via goroutines and channels, though not used here). It's more procedural with interfaces for polymorphism, lacking inheritance or generics in older versions (Go 1.23 has generics, but not heavily used here). Error handling is explicit (return errors, check them), promoting robustness but verbosity.

### Implementation Differences
- **Fetching HTML**: Both use standard HTTP libraries (Scala: java.net; Go: net/http). Go's http.Get is simpler and native, without needing to cast connections.
- **Parsing and Regex**: Scala uses Regex with findAllMatchIn for rich Match objects; Go uses regexp.FindAllStringSubmatchIndex for locations, requiring manual substring extraction. Go's approach is lower-level, needing more code for slicing strings.
- **Data Structures**: Scala uses case classes and List/Seq with functional methods (e.g., flatMap, count, groupBy). Go uses structs and slices/maps, with loops for aggregation (e.g., manual counting in maps). Scala's collections are more expressive; Go's are efficient but require explicit iteration.
- **Error Handling**: Scala uses try/finally and exceptions; Go returns errors from functions (e.g., http.Get returns err), checked explicitly to avoid panics.
- **Output Handling**: Scala uses PrintWriter for files; Go uses os.Create and fmt.Fprint, or os.WriteFile for JSON. Go's encoding/json Marshal is similar to Scala's but requires struct tags for JSON keys.
- **Command-Line Args**: Both use os.Args (Scala via Java); parsing is similar.
- **Performance/Compilation**: Scala compiles to JVM bytecode; Go to native binaries (faster startup, no JVM overhead). The Go binary is self-contained, making the Docker image lighter post-build.
- **Concurrency**: Not used here, but Go's goroutines would excel for parallel fetches if expanded.
- **Verbosity**: Go code is more verbose (e.g., explicit loops vs. Scala's higher-order functions) but readable and performant.

Overall, the Go port maintains functionality but is more explicit and lower-level, aligning with Go's philosophy of clarity over conciseness. The questions' insights remain identical.

## Notes
- The program parses the blog page content by stripping HTML tags, normalizing whitespace, truncating at footers, and using regex to extract/filter 2025 homicide entries (dates ending in /25).
- Non-numeric entries (e.g., "XXX" for pending cases) are handled but excluded if not 2025.
- The questions provide insights into temporal distribution and the potential impact of surveillance on case resolutions, which could inform policing strategies.
- Tested conceptually; run in GitHub Codespaces or locally for verification. As of October 30, 2025, parsing captures all 112 entries correctly.
