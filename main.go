package main

import (
    "encoding/csv"
    "encoding/json"
    "fmt"
    "os"
)

type Record struct {
    Field1 string `json:"field1"`
    Field2 string `json:"field2"`
}

func main() {
    records := []Record{
        {"A", "1"},
        {"B", "2"},
    }

    // Create output directory if it doesn't exist
    os.Mkdir("output", 0755)

    // Write CSV
    csvFile, _ := os.Create("output/results.csv")
    writer := csv.NewWriter(csvFile)
    writer.Write([]string{"Field1", "Field2"})
    for _, r := range records {
        writer.Write([]string{r.Field1, r.Field2})
    }
    writer.Flush()

    // Write JSON
    jsonFile, _ := os.Create("output/results.json")
    json.NewEncoder(jsonFile).Encode(records)

    fmt.Println("Kamari's Go version of Project 5 is now finally done and ready to turn in.")
}