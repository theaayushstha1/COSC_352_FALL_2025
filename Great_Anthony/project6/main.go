package main

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"
)

// HomicideRecord represents a single homicide record
type HomicideRecord struct {
	UID         string
	Date        time.Time
	VictimName  string
	Age         *int
	City        string
	State       string
	Disposition string
}

// AnalysisResult holds the analysis results
type AnalysisResult struct {
	TotalHomicides int                `json:"total_homicides"`
	CasesClosed    int                `json:"cases_closed"`
	CasesOpen      int                `json:"cases_open"`
	AverageAge     float64            `json:"average_age"`
	ByYear         []YearCount        `json:"by_year"`
	ByMonth        []MonthCount       `json:"by_month"`
	ByDisposition  []DispositionCount `json:"by_disposition"`
}

type YearCount struct {
	Year  int `json:"year"`
	Count int `json:"count"`
}

type MonthCount struct {
	Month int `json:"month"`
	Count int `json:"count"`
}

type DispositionCount struct {
	Disposition string `json:"disposition"`
	Count       int    `json:"count"`
}

func main() {
	outputFormat := "stdout"
	if len(os.Args) > 1 {
		outputFormat = os.Args[1]
	}

	fmt.Printf("Starting Baltimore Homicide Analysis with output format: %s\n", outputFormat)

	records, err := readHomicideData("data/homicide-data.csv")
	if err != nil {
		log.Fatalf("Error reading data: %v", err)
	}

	fmt.Printf("Successfully loaded %d records\n", len(records))

	analysis := analyzeData(records)

	switch strings.ToLower(outputFormat) {
	case "csv":
		writeCSV(analysis)
	case "json":
		writeJSON(analysis)
	default:
		writeStdout(analysis)
	}
}

func readHomicideData(filename string) ([]HomicideRecord, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	reader := csv.NewReader(file)
	
	// Read header
	_, err = reader.Read()
	if err != nil {
		return nil, fmt.Errorf("failed to read header: %w", err)
	}

	var records []HomicideRecord

	for {
		line, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			continue // Skip malformed lines
		}

		if len(line) < 12 {
			continue
		}

		// Parse date (format: yyyyMMdd)
		dateStr := strings.TrimSpace(line[1])
		date, err := time.Parse("20060102", dateStr)
		if err != nil {
			date = time.Now() // Default to current date if parsing fails
		}

		// Parse age (optional)
		var age *int
		if ageStr := strings.TrimSpace(line[5]); ageStr != "" {
			if ageVal, err := strconv.Atoi(ageStr); err == nil {
				age = &ageVal
			}
		}

		record := HomicideRecord{
			UID:         strings.TrimSpace(line[0]),
			Date:        date,
			VictimName:  fmt.Sprintf("%s %s", strings.TrimSpace(line[3]), strings.TrimSpace(line[2])),
			Age:         age,
			City:        strings.TrimSpace(line[7]),
			State:       strings.TrimSpace(line[8]),
			Disposition: strings.TrimSpace(line[11]),
		}

		records = append(records, record)
	}

	return records, nil
}

func analyzeData(records []HomicideRecord) AnalysisResult {
	// Filter for Baltimore (case-insensitive)
	var baltimoreRecords []HomicideRecord
	for _, r := range records {
		if strings.EqualFold(r.City, "Baltimore") {
			baltimoreRecords = append(baltimoreRecords, r)
		}
	}

	fmt.Printf("Found %d Baltimore records\n", len(baltimoreRecords))

	// Count closed cases
	closedCases := 0
	for _, r := range baltimoreRecords {
		if strings.Contains(strings.ToLower(r.Disposition), "closed") {
			closedCases++
		}
	}

	// Calculate average age
	var ageSum int
	var ageCount int
	for _, r := range baltimoreRecords {
		if r.Age != nil {
			ageSum += *r.Age
			ageCount++
		}
	}
	averageAge := 0.0
	if ageCount > 0 {
		averageAge = float64(ageSum) / float64(ageCount)
	}

	// Group by year
	yearMap := make(map[int]int)
	for _, r := range baltimoreRecords {
		yearMap[r.Date.Year()]++
	}
	var byYear []YearCount
	for year, count := range yearMap {
		byYear = append(byYear, YearCount{Year: year, Count: count})
	}
	sort.Slice(byYear, func(i, j int) bool {
		return byYear[i].Year < byYear[j].Year
	})

	// Group by month
	monthMap := make(map[int]int)
	for _, r := range baltimoreRecords {
		monthMap[int(r.Date.Month())]++
	}
	var byMonth []MonthCount
	for month, count := range monthMap {
		byMonth = append(byMonth, MonthCount{Month: month, Count: count})
	}
	sort.Slice(byMonth, func(i, j int) bool {
		return byMonth[i].Month < byMonth[j].Month
	})

	// Group by disposition
	dispMap := make(map[string]int)
	for _, r := range baltimoreRecords {
		dispMap[r.Disposition]++
	}
	var byDisposition []DispositionCount
	for disp, count := range dispMap {
		byDisposition = append(byDisposition, DispositionCount{Disposition: disp, Count: count})
	}
	sort.Slice(byDisposition, func(i, j int) bool {
		return byDisposition[i].Count > byDisposition[j].Count
	})

	return AnalysisResult{
		TotalHomicides: len(baltimoreRecords),
		CasesClosed:    closedCases,
		CasesOpen:      len(baltimoreRecords) - closedCases,
		AverageAge:     averageAge,
		ByYear:         byYear,
		ByMonth:        byMonth,
		ByDisposition:  byDisposition,
	}
}

func writeStdout(analysis AnalysisResult) {
	fmt.Println("\n=== Baltimore Homicide Statistics ===")
	fmt.Printf("Total Homicides: %d\n", analysis.TotalHomicides)
	fmt.Printf("Cases Closed: %d\n", analysis.CasesClosed)
	fmt.Printf("Cases Open: %d\n", analysis.CasesOpen)
	fmt.Printf("Average Age: %.1f\n", analysis.AverageAge)

	fmt.Println("\n=== Homicides by Year ===")
	for _, yc := range analysis.ByYear {
		fmt.Printf("%d: %d\n", yc.Year, yc.Count)
	}

	fmt.Println("\n=== Homicides by Month ===")
	for _, mc := range analysis.ByMonth {
		fmt.Printf("Month %d: %d\n", mc.Month, mc.Count)
	}

	fmt.Println("\n=== Top Dispositions ===")
	for i, dc := range analysis.ByDisposition {
		if i >= 5 {
			break
		}
		fmt.Printf("%s: %d\n", dc.Disposition, dc.Count)
	}
}

func writeCSV(analysis AnalysisResult) {
	file, err := os.Create("output.csv")
	if err != nil {
		log.Fatalf("Failed to create output.csv: %v", err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Write summary statistics
	writer.Write([]string{"Metric", "Value"})
	writer.Write([]string{"Total Homicides", strconv.Itoa(analysis.TotalHomicides)})
	writer.Write([]string{"Cases Closed", strconv.Itoa(analysis.CasesClosed)})
	writer.Write([]string{"Cases Open", strconv.Itoa(analysis.CasesOpen)})
	writer.Write([]string{"Average Age", fmt.Sprintf("%.1f", analysis.AverageAge)})

	writer.Write([]string{})
	writer.Write([]string{"Year", "Count"})
	for _, yc := range analysis.ByYear {
		writer.Write([]string{strconv.Itoa(yc.Year), strconv.Itoa(yc.Count)})
	}

	writer.Write([]string{})
	writer.Write([]string{"Month", "Count"})
	for _, mc := range analysis.ByMonth {
		writer.Write([]string{strconv.Itoa(mc.Month), strconv.Itoa(mc.Count)})
	}

	writer.Write([]string{})
	writer.Write([]string{"Disposition", "Count"})
	for _, dc := range analysis.ByDisposition {
		writer.Write([]string{dc.Disposition, strconv.Itoa(dc.Count)})
	}

	fmt.Println("Output written to output.csv")
}

func writeJSON(analysis AnalysisResult) {
	file, err := os.Create("output.json")
	if err != nil {
		log.Fatalf("Failed to create output.json: %v", err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")

	if err := encoder.Encode(analysis); err != nil {
		log.Fatalf("Failed to encode JSON: %v", err)
	}

	fmt.Println("Output written to output.json")
}
