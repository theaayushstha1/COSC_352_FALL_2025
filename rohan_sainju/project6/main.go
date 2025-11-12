package main

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Homicide struct {
	No         string
	Date       string
	Name       string
	Age        string
	Address    string
	Notes      string
	Camera     string
	CaseClosed string
}

type AnalysisResult struct {
	VictimsUnder18 int `json:"victims_under_18"`
	ClosedCases    int `json:"closed_cases"`
	OpenCases      int `json:"open_cases"`
	UnknownCases   int `json:"unknown_cases"`
	TotalCases     int `json:"total_cases"`
}

func main() {
	outputFormat := "stdout"
	if len(os.Args) > 1 {
		arg := os.Args[1]
		if strings.HasPrefix(arg, "--output=") {
			outputFormat = strings.TrimPrefix(arg, "--output=")
		}
	}

	homicides, err := readCSV("homicides.csv")
	if err != nil {
		fmt.Printf("Error reading CSV: %v\n", err)
		return
	}

	result := analyzeData(homicides)

	switch outputFormat {
	case "csv":
		writeCSV(result)
	case "json":
		writeJSON(result)
	default:
		writeStdout(result)
	}
}

func readCSV(filename string) ([]Homicide, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	reader := csv.NewReader(file)
	records, err := reader.ReadAll()
	if err != nil {
		return nil, err
	}

	var homicides []Homicide
	for i, record := range records {
		if i == 0 {
			continue // Skip header
		}
		if len(record) >= 8 {
			homicides = append(homicides, Homicide{
				No:         record[0],
				Date:       record[1],
				Name:       record[2],
				Age:        record[3],
				Address:    record[4],
				Notes:      record[5],
				Camera:     record[6],
				CaseClosed: record[7],
			})
		}
	}
	return homicides, nil
}

func analyzeData(homicides []Homicide) AnalysisResult {
	result := AnalysisResult{TotalCases: len(homicides)}

	for _, h := range homicides {
		// Count victims under 18
		age, err := strconv.Atoi(h.Age)
		if err == nil && age < 18 {
			result.VictimsUnder18++
		}

		// Count closed vs open vs unknown cases
		status := strings.ToLower(strings.TrimSpace(h.CaseClosed))
		if status == "closed" {
			result.ClosedCases++
		} else if status == "open" {
			result.OpenCases++
		} else {
			result.UnknownCases++
		}
	}

	return result
}

func writeStdout(result AnalysisResult) {
	fmt.Println("Baltimore Homicide Analysis Results")
	fmt.Println("====================================")
	fmt.Printf("Total cases analyzed: %d\n\n", result.TotalCases)
	fmt.Printf("Victims under 18 years old: %d\n\n", result.VictimsUnder18)
	fmt.Printf("Closed cases: %d (%.1f%%)\n", result.ClosedCases, 
		float64(result.ClosedCases)/float64(result.TotalCases)*100)
	fmt.Printf("Open cases: %d (%.1f%%)\n", result.OpenCases,
		float64(result.OpenCases)/float64(result.TotalCases)*100)
	fmt.Printf("Unknown cases: %d (%.1f%%)\n", result.UnknownCases,
		float64(result.UnknownCases)/float64(result.TotalCases)*100)
}

func writeCSV(result AnalysisResult) {
	file, err := os.Create("output.csv")
	if err != nil {
		fmt.Printf("Error creating CSV: %v\n", err)
		return
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"Metric", "Value"})
	writer.Write([]string{"Total Cases", strconv.Itoa(result.TotalCases)})
	writer.Write([]string{"Victims Under 18", strconv.Itoa(result.VictimsUnder18)})
	writer.Write([]string{"Closed Cases", strconv.Itoa(result.ClosedCases)})
	writer.Write([]string{"Open Cases", strconv.Itoa(result.OpenCases)})
	writer.Write([]string{"Unknown Cases", strconv.Itoa(result.UnknownCases)})

	fmt.Println("CSV output written to output.csv")
}

func writeJSON(result AnalysisResult) {
	file, err := os.Create("output.json")
	if err != nil {
		fmt.Printf("Error creating JSON: %v\n", err)
		return
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(result); err != nil {
		fmt.Printf("Error encoding JSON: %v\n", err)
		return
	}

	fmt.Println("JSON output written to output.json")
}