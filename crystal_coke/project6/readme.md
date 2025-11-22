# Baltimore Homicide Analyzer (Go Port)

This is a Golang port of the Project 5 Scala program.  
It fetches Baltimore homicide data from a blog URL, parses the HTML table,
filters 2025 records, and reports:
- total records
- closed cases
- shooting victims

## Run (locally)
```bash
go run ./cmd/analyzer
go run ./cmd/analyzer csv
go run ./cmd/analyzer json
