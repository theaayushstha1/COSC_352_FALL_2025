package main

import (
    "encoding/csv"
    "fmt"
    "log"
    "os"
    "strconv"
    "strings"
)

// categorizeAge returns a label based on age
func categorizeAge(ageStr string) string {
    age, err := strconv.Atoi(ageStr)
    if err != nil {
        return "Unknown"
    }
    switch {
    case age >= 13 && age <= 19:
        return "Teen"
    case age >= 20 && age <= 29:
        return "Young Adult"
    case age >= 30 && age <= 49:
        return "Adult"
    case age >= 50:
        return "Senior"
    default:
        return "Unknown"
    }
}

func main() {
    // Open the CSV file
    file, err := os.Open("data/homicides.csv")
    if err != nil {
        log.Fatalf("Failed to open CSV file: %v", err)
    }
    defer file.Close()

    // Read all records
    reader := csv.NewReader(file)
    records, err := reader.ReadAll()
    if err != nil {
        log.Fatalf("Failed to read CSV: %v", err)
    }

    fmt.Printf("Loaded %d rows from homicides.csv\n", len(records)-1)

    // Print first 5 rows (Year, Age, CriminalHistory)
    for i, row := range records[1:] {
        if len(row) < 3 {
            continue
        }
        fmt.Printf("Row %d: Year=%s, Age=%s, CriminalHistory=%s\n", i+1, row[0], row[1], row[2])
        if i == 4 {
            break
        }
    }

    // Count homicides by year
    yearCounts := make(map[string]int)
    for _, row := range records[1:] {
        if len(row) < 1 {
            continue
        }
        year := row[0]
        yearCounts[year]++
    }

    fmt.Println("\nHomicides by Year:")
    for year, count := range yearCounts {
        fmt.Printf("%s: %d\n", year, count)
    }

    // Count by age group
    ageGroups := make(map[string]int)
    for _, row := range records[1:] {
        if len(row) < 2 {
            continue
        }
        group := categorizeAge(row[1])
        ageGroups[group]++
    }

    fmt.Println("\nHomicides by Age Group:")
    for group, count := range ageGroups {
        fmt.Printf("%s: %d\n", group, count)
    }

    // Count by CriminalHistory
    historyCounts := make(map[string]int)
    for _, row := range records[1:] {
        if len(row) < 3 {
            continue
        }
        history := strings.TrimSpace(row[2])
        if history == "" || history == "Not checked yet" {
            history = "Unknown"
        }
        historyCounts[history]++
    }

    fmt.Println("\nHomicides by Criminal History:")
    for history, count := range historyCounts {
        fmt.Printf("%s: %d\n", history, count)
    }
}

