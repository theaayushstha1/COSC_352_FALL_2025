package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/gocolly/colly/v2"
)

// Homicide represents a single homicide record
type Homicide struct {
	Date        string `json:"date"`
	Victim      string `json:"victim"`
	Age         string `json:"age"`
	Gender      string `json:"gender"`
	Race        string `json:"race"`
	Cause       string `json:"cause"`
	Location    string `json:"location"`
	Disposition string `json:"disposition"`
}

// JSONOutput represents the JSON output structure
type JSONOutput struct {
	Metadata struct {
		Source       string `json:"source"`
		TotalRecords int    `json:"total_records"`
		GeneratedAt  string `json:"generated_at"`
	} `json:"metadata"`
	Homicides []Homicide `json:"homicides"`
}

func main() {
	// Parse command line arguments
	outputFormat := flag.String("output", "stdout", "Output format: stdout, csv, or json")
	flag.Parse()

	// Scrape the data
	homicides, err := scrapeData()
	if err != nil {
		log.Fatalf("Error scraping data: %v", err)
	}

	// Output in the specified format
	switch strings.ToLower(*outputFormat) {
	case "csv":
		if err := outputCSV(homicides); err != nil {
			log.Fatalf("Error writing CSV: %v", err)
		}
	case "json":
		if err := outputJSON(homicides); err != nil {
			log.Fatalf("Error writing JSON: %v", err)
		}
	case "stdout":
		outputStdout(homicides)
	default:
		fmt.Printf("Unknown output format: %s\n", *outputFormat)
		fmt.Println("Valid formats: stdout, csv, json")
		os.Exit(1)
	}
}

func scrapeData() ([]Homicide, error) {
	var homicides []Homicide

	c := colly.NewCollector(
		colly.AllowedDomains("chamspage.blogspot.com"),
	)

	// Find and parse table rows
	c.OnHTML("table tr", func(e *colly.HTMLElement) {
		// Skip header row
		if e.Index == 0 {
			return
		}

		var cells []string
		e.ForEach("td", func(_ int, el *colly.HTMLElement) {
			cells = append(cells, strings.TrimSpace(el.Text))
		})

		// Only process rows with 8 or more cells
		if len(cells) >= 8 {
			homicide := Homicide{
				Date:        cells[0],
				Victim:      cells[1],
				Age:         cells[2],
				Gender:      cells[3],
				Race:        cells[4],
				Cause:       cells[5],
				Location:    cells[6],
				Disposition: cells[7],
			}
			homicides = append(homicides, homicide)
		}
	})

	c.OnError(func(r *colly.Response, err error) {
		log.Printf("Request URL: %s failed with response: %v\nError: %v",
			r.Request.URL, r, err)
	})

	err := c.Visit("https://chamspage.blogspot.com/")
	if err != nil {
		return nil, err
	}

	return homicides, nil
}

func outputStdout(homicides []Homicide) {
	fmt.Println("Baltimore Homicide Data")
	fmt.Println(strings.Repeat("=", 80))
	fmt.Printf("%-12s %-25s %-5s %-8s %-10s\n", "Date", "Victim", "Age", "Gender", "Race")
	fmt.Println(strings.Repeat("-", 80))

	for _, h := range homicides {
		fmt.Printf("%-12s %-25s %-5s %-8s %-10s\n",
			h.Date, truncate(h.Victim, 25), h.Age, h.Gender, h.Race)
	}

	fmt.Println(strings.Repeat("-", 80))
	fmt.Printf("Total records: %d\n", len(homicides))
}

func outputCSV(homicides []Homicide) error {
	// Create output directory
	if err := os.MkdirAll("output", 0755); err != nil {
		return err
	}

	file, err := os.Create("output/baltimore_homicides.csv")
	if err != nil {
		return err
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Write header
	header := []string{"date", "victim", "age", "gender", "race", "cause", "location", "disposition"}
	if err := writer.Write(header); err != nil {
		return err
	}

	// Write data rows
	for _, h := range homicides {
		record := []string{h.Date, h.Victim, h.Age, h.Gender, h.Race, h.Cause, h.Location, h.Disposition}
		if err := writer.Write(record); err != nil {
			return err
		}
	}

	fmt.Printf("CSV file written: output/baltimore_homicides.csv\n")
	fmt.Printf("Total records: %d\n", len(homicides))
	return nil
}

func outputJSON(homicides []Homicide) error {
	// Create output directory
	if err := os.MkdirAll("output", 0755); err != nil {
		return err
	}

	var output JSONOutput
	output.Metadata.Source = "Baltimore Homicide Data"
	output.Metadata.TotalRecords = len(homicides)
	output.Metadata.GeneratedAt = time.Now().Format(time.RFC3339)
	output.Homicides = homicides

	jsonData, err := json.MarshalIndent(output, "", "  ")
	if err != nil {
		return err
	}

	if err := os.WriteFile("output/baltimore_homicides.json", jsonData, 0644); err != nil {
		return err
	}

	fmt.Printf("JSON file written: output/baltimore_homicides.json\n")
	fmt.Printf("Total records: %d\n", len(homicides))
	return nil
}

func truncate(s string, max int) string {
	if len(s) <= max {
		return s
	}
	return s[:max-3] + "..."
}