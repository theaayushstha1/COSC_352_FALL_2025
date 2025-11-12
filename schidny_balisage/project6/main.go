package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"sort"
	"strings"
	"time"
)

// CrimeRecord represents a single crime entry from the CSV
type CrimeRecord struct {
	Neighborhood string
	Description  string
}

// CrimeStats holds aggregated statistics for a neighborhood
type CrimeStats struct {
	Neighborhood    string  `json:"neighborhood"`
	TotalCrimes     int     `json:"total_crimes"`
	ViolentCrimes   int     `json:"violent_crimes"`
	PropertyCrimes  int     `json:"property_crimes"`
	AveragePerMonth float64 `json:"average_per_month"`
}

// JSONOutput represents the complete JSON output structure
type JSONOutput struct {
	Metadata struct {
		Source              string `json:"source"`
		GeneratedAt         string `json:"generated_at"`
		TotalNeighborhoods int    `json:"total_neighborhoods"`
	} `json:"metadata"`
	CrimeStatistics []CrimeStats `json:"crime_statistics"`
}

func main() {
	// Parse command line flags
	outputFormat := flag.String("output", "stdout", "Output format: stdout, csv, or json")
	flag.Parse()

	// Read and parse the CSV file
	records, err := readCrimeData("/data/BPD_Part_1_Victim_Based_Crime_Data.csv")
	if err != nil {
		log.Fatalf("Error reading crime data: %v", err)
	}

	// Aggregate crime statistics by neighborhood
	stats := aggregateStats(records)

	// Sort by total crimes descending
	sort.Slice(stats, func(i, j int) bool {
		return stats[i].TotalCrimes > stats[j].TotalCrimes
	})

	// Output based on format
	switch strings.ToLower(*outputFormat) {
	case "csv":
		if err := writeCSV(stats); err != nil {
			log.Fatalf("Error writing CSV: %v", err)
		}
	case "json":
		if err := writeJSON(stats); err != nil {
			log.Fatalf("Error writing JSON: %v", err)
		}
	default:
		writeStdout(stats)
	}
}

// readCrimeData reads the CSV file and returns crime records
func readCrimeData(filename string) ([]CrimeRecord, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	reader := csv.NewReader(file)
	
	// Read header
	header, err := reader.Read()
	if err != nil {
		return nil, err
	}

	// Find column indices
	neighborhoodIdx := -1
	descriptionIdx := -1
	for i, col := range header {
		col = strings.TrimSpace(col)
		if col == "Neighborhood" {
			neighborhoodIdx = i
		} else if col == "Description" {
			descriptionIdx = i
		}
	}

	if neighborhoodIdx == -1 || descriptionIdx == -1 {
		return nil, fmt.Errorf("required columns not found in CSV")
	}

	// Read all records
	var records []CrimeRecord
	for {
		row, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			continue // Skip malformed rows
		}

		if len(row) <= neighborhoodIdx || len(row) <= descriptionIdx {
			continue
		}

		neighborhood := strings.TrimSpace(row[neighborhoodIdx])
		description := strings.TrimSpace(row[descriptionIdx])

		// Filter out empty neighborhoods
		if neighborhood == "" {
			continue
		}

		records = append(records, CrimeRecord{
			Neighborhood: neighborhood,
			Description:  description,
		})
	}

	return records, nil
}

// aggregateStats aggregates crime statistics by neighborhood
func aggregateStats(records []CrimeRecord) []CrimeStats {
	statsMap := make(map[string]*CrimeStats)

	for _, record := range records {
		stats, exists := statsMap[record.Neighborhood]
		if !exists {
			stats = &CrimeStats{
				Neighborhood: record.Neighborhood,
			}
			statsMap[record.Neighborhood] = stats
		}

		stats.TotalCrimes++

		// Check if violent crime
		desc := strings.ToUpper(record.Description)
		if strings.Contains(desc, "ASSAULT") ||
			strings.Contains(desc, "ROBBERY") ||
			strings.Contains(desc, "HOMICIDE") {
			stats.ViolentCrimes++
		}

		// Check if property crime
		if strings.Contains(desc, "BURGLARY") ||
			strings.Contains(desc, "LARCENY") ||
			strings.Contains(desc, "THEFT") {
			stats.PropertyCrimes++
		}
	}

	// Convert map to slice and calculate averages
	result := make([]CrimeStats, 0, len(statsMap))
	for _, stats := range statsMap {
		stats.AveragePerMonth = float64(stats.TotalCrimes) / 12.0
		result = append(result, *stats)
	}

	return result
}

// writeStdout writes formatted output to stdout
func writeStdout(stats []CrimeStats) {
	fmt.Println("Baltimore Crime Statistics by Neighborhood")
	fmt.Println(strings.Repeat("=", 80))
	fmt.Printf("%-30s %10s %10s %10s %10s\n", "Neighborhood", "Total", "Violent", "Property", "Avg/Month")
	fmt.Println(strings.Repeat("-", 80))
	
	for _, stat := range stats {
		fmt.Printf("%-30s %10d %10d %10d %10.2f\n",
			truncate(stat.Neighborhood, 30),
			stat.TotalCrimes,
			stat.ViolentCrimes,
			stat.PropertyCrimes,
			stat.AveragePerMonth)
	}
	
	fmt.Println(strings.Repeat("=", 80))
}

// writeCSV writes statistics to a CSV file
func writeCSV(stats []CrimeStats) error {
	filename := "baltimore_crime_stats.csv"
	file, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Write header
	if err := writer.Write([]string{
		"neighborhood",
		"total_crimes",
		"violent_crimes",
		"property_crimes",
		"average_per_month",
	}); err != nil {
		return err
	}

	// Write data rows
	for _, stat := range stats {
		if err := writer.Write([]string{
			stat.Neighborhood,
			fmt.Sprintf("%d", stat.TotalCrimes),
			fmt.Sprintf("%d", stat.ViolentCrimes),
			fmt.Sprintf("%d", stat.PropertyCrimes),
			fmt.Sprintf("%.2f", stat.AveragePerMonth),
		}); err != nil {
			return err
		}
	}

	fmt.Printf("CSV output written to: %s\n", filename)
	return nil
}

// writeJSON writes statistics to a JSON file
func writeJSON(stats []CrimeStats) error {
	filename := "baltimore_crime_stats.json"
	file, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	output := JSONOutput{}
	output.Metadata.Source = "Baltimore Police Department Part 1 Crime Data"
	output.Metadata.GeneratedAt = time.Now().Format(time.RFC3339)
	output.Metadata.TotalNeighborhoods = len(stats)
	output.CrimeStatistics = stats

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(output); err != nil {
		return err
	}

	fmt.Printf("JSON output written to: %s\n", filename)
	return nil
}

// truncate truncates a string to maxLen characters
func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen]
}
