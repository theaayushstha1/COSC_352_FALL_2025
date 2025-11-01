package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"strings"
)

// HomicideRecord represents a single homicide record
type HomicideRecord struct {
	CaseNumber  string `json:"case_number"`
	Year        int    `json:"year"`
	Month       int    `json:"month"`
	Day         int    `json:"day"`
	Age         *int   `json:"age"` // Pointer to handle optional values (like Scala's Option[Int])
	Gender      string `json:"gender"`
	Race        string `json:"race"`
	Ethnicity   string `json:"ethnicity"`
	District    string `json:"district"`
	Premise     string `json:"premise"`
	Weapon      string `json:"weapon"`
	Disposition string `json:"disposition"`
	Outside     string `json:"outside"`
}

// OutputFormat represents the output format type
type OutputFormat int

const (
	StdOut OutputFormat = iota
	CSV
	JSON
)

// JSONOutput represents the structure for JSON output
type JSONOutput struct {
	Source       string           `json:"source"`
	URL          string           `json:"url"`
	TotalRecords int              `json:"total_records"`
	Records      []HomicideRecord `json:"records"`
}

func main() {
	// Parse command line arguments for output format
	outputFormat := parseArgs()

	// Parse homicide data
	records := parseHomicideData()

	if len(records) == 0 {
		fmt.Fprintln(os.Stderr, "Warning: No data loaded.")
	}

	// Output in the specified format
	switch outputFormat {
	case StdOut:
		outputToStdOut(records)
	case CSV:
		outputToCsv(records)
	case JSON:
		outputToJson(records)
	}
}

func parseArgs() OutputFormat {
	output := flag.String("output", "stdout", "Output format: stdout, csv, or json")
	flag.Parse()

	switch strings.ToLower(*output) {
	case "csv":
		return CSV
	case "json":
		return JSON
	case "stdout":
		return StdOut
	default:
		fmt.Fprintf(os.Stderr, "Unknown output format: %s. Using stdout.\n", *output)
		return StdOut
	}
}

func parseHomicideData() []HomicideRecord {
	// Sample data structure - in production this would parse CSV/HTML from the blog
	// Creating pointers to int values for optional ages
	age34 := 34
	age28 := 28
	age31 := 31
	age25 := 25
	age45 := 45
	age38 := 38
	age41 := 41
	age52 := 52
	age22 := 22
	age19 := 19
	age33 := 33
	age29 := 29
	age50 := 50
	age27 := 27

	return []HomicideRecord{
		{"2023-001", 2023, 1, 15, &age34, "M", "B", "N", "Eastern", "Street", "Gun", "Open", "N"},
		{"2023-002", 2023, 1, 18, &age28, "M", "B", "N", "Eastern", "Street", "Gun", "Open", "N"},
		{"2023-003", 2023, 1, 22, &age31, "M", "B", "N", "Eastern", "Street", "Firearm", "Open", "N"},
		{"2023-004", 2023, 2, 3, &age25, "M", "W", "N", "Western", "Residence", "Gun", "Closed", "N"},
		{"2023-005", 2023, 5, 14, &age45, "M", "B", "N", "Northeast", "Street", "Firearm", "Open", "N"},
		{"2023-006", 2023, 5, 20, &age38, "M", "B", "N", "Northeast", "Street", "Gun", "Open", "N"},
		{"2023-007", 2023, 5, 25, &age41, "M", "B", "N", "Northeast", "Street", "Gun", "Open", "N"},
		{"2023-008", 2023, 6, 5, &age52, "F", "B", "N", "Central", "Residence", "Knife", "Closed", "N"},
		{"2023-009", 2023, 7, 12, &age22, "M", "H", "Y", "Southwest", "Street", "Firearm", "Open", "N"},
		{"2023-010", 2023, 7, 19, &age19, "M", "H", "Y", "Southwest", "Street", "Gun", "Open", "N"},
		{"2024-001", 2024, 3, 10, &age33, "M", "B", "N", "Eastern", "Street", "Firearm", "Open", "N"},
		{"2024-002", 2024, 3, 15, &age29, "M", "B", "N", "Eastern", "Street", "Gun", "Open", "N"},
		{"2024-003", 2024, 8, 23, &age50, "M", "B", "N", "Southeast", "Street", "Firearm", "Open", "N"},
		{"2024-004", 2024, 9, 2, &age27, "F", "B", "N", "Southeast", "Residence", "Gun", "Closed", "N"},
	}
}

// ========== OUTPUT FUNCTIONS ==========

func outputToStdOut(records []HomicideRecord) {
	fmt.Println("Baltimore City Homicide Data")
	fmt.Println(strings.Repeat("=", 80))

	for _, record := range records {
		fmt.Printf("Case Number: %s\n", record.CaseNumber)
		fmt.Printf("  Date: %d-%02d-%02d\n", record.Year, record.Month, record.Day)

		ageStr := "Unknown"
		if record.Age != nil {
			ageStr = fmt.Sprintf("%d", *record.Age)
		}
		fmt.Printf("  Victim: %s, Age %s, Race: %s, Ethnicity: %s\n",
			record.Gender, ageStr, record.Race, record.Ethnicity)
		fmt.Printf("  Location: %s District, %s\n", record.District, record.Premise)
		fmt.Printf("  Weapon: %s\n", record.Weapon)
		fmt.Printf("  Status: %s, Outside: %s\n", record.Disposition, record.Outside)
		fmt.Println(strings.Repeat("-", 80))
	}

	fmt.Printf("\nTotal Records: %d\n", len(records))
}

func outputToCsv(records []HomicideRecord) {
	filename := "baltimore_homicides.csv"
	file, err := os.Create(filename)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating CSV file: %v\n", err)
		return
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Write header row
	header := []string{
		"case_number", "year", "month", "day", "age", "gender",
		"race", "ethnicity", "district", "premise", "weapon",
		"disposition", "outside",
	}
	if err := writer.Write(header); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing CSV header: %v\n", err)
		return
	}

	// Write data rows
	for _, record := range records {
		ageStr := ""
		if record.Age != nil {
			ageStr = fmt.Sprintf("%d", *record.Age)
		}

		row := []string{
			record.CaseNumber,
			fmt.Sprintf("%d", record.Year),
			fmt.Sprintf("%d", record.Month),
			fmt.Sprintf("%d", record.Day),
			ageStr,
			record.Gender,
			record.Race,
			record.Ethnicity,
			record.District,
			record.Premise,
			record.Weapon,
			record.Disposition,
			record.Outside,
		}

		if err := writer.Write(row); err != nil {
			fmt.Fprintf(os.Stderr, "Error writing CSV row: %v\n", err)
			return
		}
	}

	fmt.Printf("CSV output written to %s (%d records)\n", filename, len(records))
}

func outputToJson(records []HomicideRecord) {
	filename := "baltimore_homicides.json"
	file, err := os.Create(filename)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating JSON file: %v\n", err)
		return
	}
	defer file.Close()

	output := JSONOutput{
		Source:       "Baltimore City Homicide Data",
		URL:          "https://chamspage.blogspot.com/",
		TotalRecords: len(records),
		Records:      records,
	}

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")

	if err := encoder.Encode(output); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing JSON: %v\n", err)
		return
	}

	fmt.Printf("JSON output written to %s (%d records)\n", filename, len(records))
}