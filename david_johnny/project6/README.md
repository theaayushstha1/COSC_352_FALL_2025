Project 5: Baltimore Homicide Analysis - Go Implementation
Overview
This project analyzes Baltimore homicide data from https://chamspage.blogspot.com/ and outputs the results in three different formats: stdout (default), CSV, and JSON.

This is a Go port of the original Scala implementation, maintaining identical functionality while leveraging Go's strengths in deployment and performance.

Requirements
Docker
Bash (for the run script)
Usage
Make the run script executable:

bash
chmod +x run.sh
Default Output (stdout)
bash
./run.sh
CSV Output
bash
./run.sh --output=csv
Creates a file: homicide_analysis.csv

JSON Output
bash
./run.sh --output=json
Creates a file: homicide_analysis.json

Data Format Rationale
CSV Format
The CSV format was designed to be easily imported into spreadsheet applications (Excel, Google Sheets) and queryable by data analysis tools (Python pandas, R, SQL).

Structure:

Header Row: category,subcategory,count,percentage,description
Data Rows: Each row represents a specific metric with hierarchical categories
Design Decisions:

Hierarchical Categories: Using category and subcategory columns allows for easy grouping and filtering
Always Include Counts AND Percentages: Both raw numbers and percentages are provided to support different analysis needs
Description Field: Human-readable descriptions make the CSV self-documenting
Use Cases:

Import into Excel for pivot tables and charts
Load into pandas: df = pd.read_csv('homicide_analysis.csv')
Aggregate multiple time periods by appending rows with timestamps
Easy to merge with other CSV datasets
JSON Format
The JSON format was designed for API consumption, web applications, and programmatic processing.

Structure:

json
{
  "analysis_metadata": { ... },
  "question_1": {
    "question": "...",
    "total_victims": { "count": ..., "percentage": ... },
    "victim_breakdown": { ... }
  },
  "question_2": { ... }
}
Design Decisions:

Nested Structure: Mirrors the logical hierarchy of the analysis questions
Metadata Section: Includes source URL and total victims for context and validation
Consistent Object Pattern: Every data point includes both count and percentage
Self-Documenting: Question text is embedded in the JSON for clarity
Use Cases:

REST API responses for web dashboards
Mobile app data consumption
Automated report generation
Integration with JavaScript visualization libraries (D3.js, Chart.js)
NoSQL database storage (MongoDB, etc.)
Analysis Questions
Question 1: Victim Type Distribution
What is the ratio of stabbing victims and shooting victims compared to the total?

This analysis categorizes homicide victims by weapon type (stabbing vs. shooting) to understand the predominant methods of violence in Baltimore.

Question 2: Case Closure Rates
Of these victims (stabbing or shooting), what is the ratio of closed cases?

This analysis examines the closure rate for violent crimes (stabbings and shootings) to assess investigative effectiveness and identify patterns in case resolution.

Scala vs Go Implementation Differences
1. Language Philosophy
Scala: Functional programming with immutable data structures, expression-based syntax, and advanced type inference
Go: Imperative programming with explicit error handling, simple syntax, and emphasis on clarity over cleverness
2. Error Handling
Scala: Uses exceptions and try-catch blocks; errors can propagate implicitly
Go: Explicit error returns as values; every error must be explicitly checked and handled (e.g., if err != nil)
3. HTTP Requests
Scala: Uses Java's java.net.URL and scala.io.Source for streaming data
Go: Uses native net/http package with cleaner API and built-in client management
4. Regular Expressions
Scala: scala.util.matching.Regex with functional-style matching
Go: regexp package with compiled patterns; similar functionality but different API style
5. String Processing
Scala: Rich string interpolation (f"text $variable%.2f") and collection operations
Go: Uses fmt.Printf for formatting; more verbose but explicit
6. Data Structures
Scala: Functional collections (List, Option) with methods like map, filter, flatMap
Go: Basic slices and maps; manual iteration with for loops instead of functional methods
7. File I/O
Scala: Uses java.io.PrintWriter with Java interop
Go: Native os package with simpler file operations and defer for cleanup
8. JSON Generation
Scala: Manual string concatenation for JSON output (no JSON library used in original)
Go: Uses encoding/json package with map[string]interface{} for structured JSON generation
9. Compilation & Deployment
Scala:
Compiles to JVM bytecode
Requires Java Runtime Environment
Docker image: ~600-800MB
Startup time: 1-2 seconds (JVM initialization)
Go:
Compiles to native machine code binary
No runtime dependencies (static binary)
Docker image: ~10-15MB (using multi-stage build)
Startup time: Near-instantaneous
10. Docker Strategy
Scala Dockerfile: Single-stage build with full JDK, compiles at build time
Go Dockerfile: Multi-stage build that discards build tools, only keeps final binary in Alpine Linux
11. Memory Footprint
Scala: ~100-200MB (JVM overhead)
Go: ~10-50MB (native binary)
12. Code Verbosity
Scala: More concise due to functional programming features and type inference
Go: More explicit and verbose, especially for error handling and iterations
13. Null Safety
Scala: Uses Option[T] type (Some/None) for optional values
Go: Uses zero values and explicit checks; no built-in Option type
14. Package Management
Scala: No external dependencies in this project; would use sbt or Maven for complex projects
Go: No external dependencies needed; standard library provides everything (would use Go modules for external packages)
Functional Equivalence
Despite the language differences, both implementations:

✅ Fetch data from the same URL with custom User-Agent
✅ Parse HTML tables using regex
✅ Identify weapon types (stabbing vs shooting) using keyword matching
✅ Determine case status (closed vs open) using keyword matching
✅ Calculate percentages to 2 decimal places
✅ Output identical stdout, CSV, and JSON formats
✅ Support Docker volume mounting for file output
✅ Use the same command-line interface
When to Use Each
Use Go when:

Building microservices or CLI tools
Deployment simplicity and small container size are priorities
Fast startup time is critical (serverless, CI/CD tools)
Low memory footprint is needed
You want a single static binary with no dependencies
Use Scala when:

Complex data transformations benefit from functional programming
Leveraging JVM ecosystem (Spark, Akka, Play Framework)
Advanced type safety features are valuable
Team has JVM expertise
Big data processing is the primary use case
Technical Details
Dependencies
Docker
Go 1.21+ (for building)
Alpine Linux (runtime container)
File Outputs
CSV: homicide_analysis.csv - Created in the project directory
JSON: homicide_analysis.json - Created in the project directory
Data Source
Live data fetched from: https://chamspage.blogspot.com/

Future Enhancements
Add timestamp to output files for historical tracking
Support for date range filtering
Additional analysis questions (geographic distribution, time trends)
Support for multiple data sources
Add unit tests (Go's testing package makes this straightforward)
Add command-line flags using Go's flag package for better UX
