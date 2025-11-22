package main

import (
    "encoding/csv"
    "encoding/json"
    "flag"
    "fmt"
    "log"
    "os"
    "strings"
)

type Case struct {
    Year   string
    Cause  string
    Street string
    Raw    []string
}

func main() {
    inputPath := flag.String("input", "homicides.csv", "Path to input CSV")
    outputFormat := flag.String("format", "stdout", "Output format: stdout, csv, json")
    flag.Parse()

    // Auto-generate CSV if missing
    if _, err := os.Stat(*inputPath); os.IsNotExist(err) {
        fmt.Println("Input file not found. Generating default homicides.csv...")
        f, err := os.Create(*inputPath)
        if err != nil {
            log.Fatalf("Failed to create default input file: %v", err)
        }
        writer := csv.NewWriter(f)
        writer.Write([]string{"Year", "Cause", "Street"})
        writer.Write([]string{"2024", "Stabbing", "Main Avenue"})
        writer.Write([]string{"2023", "Gunshot", "Elm Street"})
        writer.Write([]string{"2024", "Stab wound", "Broadway Avenue"})
        writer.Flush()
        f.Close()
    }

    file, err := os.Open(*inputPath)
    if err != nil {
        log.Fatalf("Failed to open input file: %v", err)
    }
    defer file.Close()

    reader := csv.NewReader(file)
    records, err := reader.ReadAll()
    if err != nil {
        log.Fatalf("Failed to read CSV: %v", err)
    }

    if len(records) < 1 {
        log.Fatal("CSV file is empty or missing headers")
    }

    headers := records[0]
    data := records[1:]

    var cases []Case
    var stabbing2024Count int
    var avenueCases []Case

    for _, row := range data {
        record := map[string]string{}
        for i, val := range row {
            record[headers[i]] = val
        }

        c := Case{
            Year:   record["Year"],
            Cause:  record["Cause"],
            Street: record["Street"],
            Raw:    row,
        }

        if c.Year == "2024" && strings.Contains(strings.ToLower(c.Cause), "stab") {
            stabbing2024Count++
        }

        if strings.Contains(strings.ToLower(c.Street), "avenue") {
            avenueCases = append(avenueCases, c)
        }

        cases = append(cases, c)
    }

    switch *outputFormat {
    case "stdout":
        fmt.Printf("Total 2024 stabbing cases: %d\n", stabbing2024Count)
        fmt.Println("Cases with 'Avenue' in street name:")
        for _, c := range avenueCases {
            fmt.Println(c.Raw)
        }
    case "csv":
        out, _ := os.Create("output.csv")
        writer := csv.NewWriter(out)
        writer.Write(headers)
        for _, c := range avenueCases {
            writer.Write(c.Raw)
        }
        writer.Flush()
    case "json":
        out, _ := os.Create("output.json")
        json.NewEncoder(out).Encode(avenueCases)
    default:
        log.Fatalf("Unknown format: %s", *outputFormat)
    }
}
