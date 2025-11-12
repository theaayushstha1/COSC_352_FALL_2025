package main

import (
    "encoding/csv"
    "encoding/json"
    "fmt"
    "os"
    "log"
)

type QA struct {
    Question string `json:"question"`
    Answer   string `json:"answer"`
}

func readCSV(filename string) {
    file, err := os.Open(filename)
    if err != nil {
        log.Fatalf("Error opening CSV file: %v", err)
    }
    defer file.Close()

    reader := csv.NewReader(file)
    records, err := reader.ReadAll()
    if err != nil {
        log.Fatalf("Error reading CSV file: %v", err)
    }

    fmt.Println("📊 CSV Data:")
    for _, record := range records {
        fmt.Println(record)
    }
}

func readJSON(filename string) {
    file, err := os.Open(filename)
    if err != nil {
        log.Fatalf("Error opening JSON file: %v", err)
    }
    defer file.Close()

    var qas []QA
    decoder := json.NewDecoder(file)
    err = decoder.Decode(&qas)
    if err != nil {
        log.Fatalf("Error decoding JSON: %v", err)
    }

    fmt.Println("\n🧠 JSON Data:")
    for _, qa := range qas {
        fmt.Printf("Q: %s\nA: %s\n\n", qa.Question, qa.Answer)
    }
}

func main() {
    fmt.Println("=== Baltimore Homicide Data ===")

    readCSV("baltimore_homicide_answers.csv")
    readJSON("baltimore_homicide_answers.json")

    fmt.Println("✅ Data processing complete.")
}
