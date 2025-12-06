package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"sort"
	"strings"
)

// Homicide represents a single homicide record
type Homicide struct {
	No                   string
	DateDied             string
	Name                 string
	Age                  string
	AddressBlock         string
	Notes                string
	NoCriminalHistory    string
	SurveillanceCamera   string
	CaseClosed           string
}

// AddressStats represents statistics for an address block
type AddressStats struct {
	Address string
	Count   int
	Victims []Homicide
}

// MonthStats represents statistics for a month
type MonthStats struct {
	Month      string
	MonthName  string
	Count      int
	Percentage float64
}

func main() {
	// Parse command line arguments
	outputFormat := parseArgs()

	// Read and parse CSV
	csvFile := "chamspage_table1.csv"
	homicides, err := parseCSV(csvFile)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}

	// Analyze data
	addressStats := analyzeAddressBlocks(homicides)
	monthStats := analyzeMonths(homicides)

	// Output based on format
	switch outputFormat {
	case "csv":
		outputCSV(homicides, addressStats, monthStats)
	case "json":
		outputJSON(homicides, addressStats, monthStats)
	default:
		outputStdout(homicides, addressStats, monthStats)
	}
}

func parseArgs() string {
	for _, arg := range os.Args[1:] {
		if strings.HasPrefix(arg, "--output=") {
			format := strings.ToLower(strings.TrimPrefix(arg, "--output="))
			if format == "csv" || format == "json" {
				return format
			}
		}
	}
	return "stdout"
}

func parseCSV(filename string) ([]Homicide, error) {
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

	// Skip header row
	if len(records) < 2 {
		return nil, fmt.Errorf("CSV file is empty or has no data rows")
	}

	var homicides []Homicide
	for _, record := range records[1:] {
		if len(record) >= 9 {
			homicides = append(homicides, Homicide{
				No:                 record[0],
				DateDied:           record[1],
				Name:               record[2],
				Age:                record[3],
				AddressBlock:       record[4],
				Notes:              record[5],
				NoCriminalHistory:  record[6],
				SurveillanceCamera: record[7],
				CaseClosed:         record[8],
			})
		}
	}

	return homicides, nil
}

func analyzeAddressBlocks(homicides []Homicide) []AddressStats {
	// Group by address
	addressMap := make(map[string][]Homicide)
	for _, h := range homicides {
		if strings.TrimSpace(h.AddressBlock) != "" {
			addressMap[h.AddressBlock] = append(addressMap[h.AddressBlock], h)
		}
	}

	// Convert to slice and filter
	var stats []AddressStats
	for address, victims := range addressMap {
		if len(victims) >= 2 {
			stats = append(stats, AddressStats{
				Address: address,
				Count:   len(victims),
				Victims: victims,
			})
		}
	}

	// Sort by count (descending)
	sort.Slice(stats, func(i, j int) bool {
		return stats[i].Count > stats[j].Count
	})

	return stats
}

func analyzeMonths(homicides []Homicide) []MonthStats {
	monthNames := map[string]string{
		"01": "January", "02": "February", "03": "March",
		"04": "April", "05": "May", "06": "June",
		"07": "July", "08": "August", "09": "September",
		"10": "October", "11": "November", "12": "December",
	}

	// Count by month
	monthCounts := make(map[string]int)
	for _, h := range homicides {
		parts := strings.Split(h.DateDied, "/")
		if len(parts) >= 2 {
			month := parts[0]
			monthCounts[month]++
		}
	}

	// Convert to slice
	var stats []MonthStats
	total := float64(len(homicides))
	for month, count := range monthCounts {
		name := monthNames[month]
		if name == "" {
			name = month
		}
		stats = append(stats, MonthStats{
			Month:      month,
			MonthName:  name,
			Count:      count,
			Percentage: (float64(count) / total) * 100,
		})
	}

	// Sort by count (descending)
	sort.Slice(stats, func(i, j int) bool {
		return stats[i].Count > stats[j].Count
	})

	return stats
}

func outputStdout(homicides []Homicide, addressStats []AddressStats, monthStats []MonthStats) {
	fmt.Printf("Loaded %d homicide records\n", len(homicides))
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println()

	fmt.Println("Question 1: Which address blocks have the most repeated homicides?")
	fmt.Println()

	// Count unique addresses
	addressMap := make(map[string]int)
	for _, h := range homicides {
		if strings.TrimSpace(h.AddressBlock) != "" {
			addressMap[h.AddressBlock]++
		}
	}

	fmt.Printf("Total unique address blocks: %d\n", len(addressMap))
	fmt.Printf("Address blocks with repeated homicides (2+): %d\n", len(addressStats))
	fmt.Println()

	fmt.Println("Top 15 address blocks with most homicides:")
	for i, stat := range addressStats {
		if i >= 15 {
			break
		}
		fmt.Printf("  %2d. %-40s: %3d homicides\n", i+1, stat.Address, stat.Count)
	}

	fmt.Println()
	fmt.Println("Details for top hotspot:")
	if len(addressStats) > 0 {
		top := addressStats[0]
		fmt.Printf("Location: %s\n", top.Address)
		fmt.Printf("Total homicides: %d\n", top.Count)
		fmt.Println()
		fmt.Println("Victims at this location:")
		for _, h := range top.Victims {
			fmt.Printf("  %-12s | %-30s | Age: %3s\n", h.DateDied, h.Name, h.Age)
		}
	}

	fmt.Println()
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println()

	fmt.Println("Question 2: Which months have the highest homicide rates?")
	fmt.Println()
	fmt.Println("Homicides by month (all years combined):")
	fmt.Println()

	for _, stat := range monthStats {
		fmt.Printf("  %-12s: %3d homicides (%5.1f%%)\n", stat.MonthName, stat.Count, stat.Percentage)
	}

	fmt.Println()
	if len(monthStats) > 0 {
		deadliest := monthStats[0]
		fmt.Printf("Deadliest month: %s with %d homicides\n", deadliest.MonthName, deadliest.Count)

		// Find victims in deadliest month
		var victimsInMonth []Homicide
		for _, h := range homicides {
			if strings.HasPrefix(h.DateDied, deadliest.Month+"/") {
				victimsInMonth = append(victimsInMonth, h)
			}
		}

		fmt.Println()
		fmt.Printf("Sample victims from %s (first 10):\n", deadliest.MonthName)
		for i, h := range victimsInMonth {
			if i >= 10 {
				break
			}
			fmt.Printf("  %-12s | %-30s | %s\n", h.DateDied, h.Name, h.AddressBlock)
		}
	}
}

func outputCSV(homicides []Homicide, addressStats []AddressStats, monthStats []MonthStats) {
	file, err := os.Create("homicide_analysis.csv")
	if err != nil {
		fmt.Printf("Error creating CSV file: %v\n", err)
		return
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Write report header
	writer.Write([]string{"Baltimore Homicide Analysis Report"})
	writer.Write([]string{"Total Records", fmt.Sprintf("%d", len(homicides))})
	writer.Write([]string{})

	// Question 1
	writer.Write([]string{"QUESTION 1: Which address blocks have the most repeated homicides?"})
	writer.Write([]string{"ADDRESS BLOCK ANALYSIS"})
	writer.Write([]string{"Rank", "Address Block", "Homicide Count"})

	for i, stat := range addressStats {
		if i >= 20 {
			break
		}
		writer.Write([]string{fmt.Sprintf("%d", i+1), stat.Address, fmt.Sprintf("%d", stat.Count)})
	}
	writer.Write([]string{})

	// Top address details
	writer.Write([]string{"TOP ADDRESS BLOCK DETAILS"})
	if len(addressStats) > 0 {
		top := addressStats[0]
		writer.Write([]string{"Location", top.Address})
		writer.Write([]string{"Total Homicides", fmt.Sprintf("%d", top.Count)})
		writer.Write([]string{})
		writer.Write([]string{"Date", "Name", "Age"})
		for _, h := range top.Victims {
			writer.Write([]string{h.DateDied, h.Name, h.Age})
		}
	}
	writer.Write([]string{})

	// Question 2
	writer.Write([]string{"QUESTION 2: Which months have the highest homicide rates?"})
	writer.Write([]string{"MONTHLY ANALYSIS"})
	writer.Write([]string{"Month", "Month Name", "Homicide Count", "Percentage"})

	for _, stat := range monthStats {
		writer.Write([]string{
			stat.Month,
			stat.MonthName,
			fmt.Sprintf("%d", stat.Count),
			fmt.Sprintf("%.2f", stat.Percentage),
		})
	}

	fmt.Println("✅ CSV file 'homicide_analysis.csv' created successfully!")
}

func outputJSON(homicides []Homicide, addressStats []AddressStats, monthStats []MonthStats) {
	file, err := os.Create("homicide_analysis.json")
	if err != nil {
		fmt.Printf("Error creating JSON file: %v\n", err)
		return
	}
	defer file.Close()

	fmt.Fprintln(file, "{")
	fmt.Fprintf(file, "  \"report_title\": \"Baltimore Homicide Analysis\",\n")
	fmt.Fprintf(file, "  \"total_records\": %d,\n", len(homicides))
	fmt.Fprintln(file, "  \"address_block_analysis\": {")

	// Count unique addresses
	addressMap := make(map[string]bool)
	for _, h := range homicides {
		if strings.TrimSpace(h.AddressBlock) != "" {
			addressMap[h.AddressBlock] = true
		}
	}

	fmt.Fprintf(file, "    \"total_unique_addresses\": %d,\n", len(addressMap))
	fmt.Fprintf(file, "    \"addresses_with_repeats\": %d,\n", len(addressStats))
	fmt.Fprintln(file, "    \"top_addresses\": [")

	for i, stat := range addressStats {
		if i >= 20 {
			break
		}
		comma := ","
		if i == len(addressStats)-1 || i == 19 {
			comma = ""
		}
		fmt.Fprintln(file, "      {")
		fmt.Fprintf(file, "        \"rank\": %d,\n", i+1)
		fmt.Fprintf(file, "        \"address\": \"%s\",\n", escapeJSON(stat.Address))
		fmt.Fprintf(file, "        \"homicide_count\": %d\n", stat.Count)
		fmt.Fprintf(file, "      }%s\n", comma)
	}

	fmt.Fprintln(file, "    ],")
	fmt.Fprintln(file, "    \"top_address_details\": {")

	if len(addressStats) > 0 {
		top := addressStats[0]
		fmt.Fprintf(file, "      \"location\": \"%s\",\n", escapeJSON(top.Address))
		fmt.Fprintf(file, "      \"total_homicides\": %d,\n", top.Count)
		fmt.Fprintln(file, "      \"victims\": [")

		for i, h := range top.Victims {
			comma := ","
			if i == len(top.Victims)-1 {
				comma = ""
			}
			fmt.Fprintln(file, "        {")
			fmt.Fprintf(file, "          \"date\": \"%s\",\n", h.DateDied)
			fmt.Fprintf(file, "          \"name\": \"%s\",\n", escapeJSON(h.Name))
			fmt.Fprintf(file, "          \"age\": \"%s\"\n", h.Age)
			fmt.Fprintf(file, "        }%s\n", comma)
		}

		fmt.Fprintln(file, "      ]")
	}

	fmt.Fprintln(file, "    }")
	fmt.Fprintln(file, "  },")
	fmt.Fprintln(file, "  \"monthly_analysis\": {")
	fmt.Fprintln(file, "    \"months\": [")

	for i, stat := range monthStats {
		comma := ","
		if i == len(monthStats)-1 {
			comma = ""
		}
		fmt.Fprintln(file, "      {")
		fmt.Fprintf(file, "        \"month\": \"%s\",\n", stat.Month)
		fmt.Fprintf(file, "        \"month_name\": \"%s\",\n", stat.MonthName)
		fmt.Fprintf(file, "        \"homicide_count\": %d,\n", stat.Count)
		fmt.Fprintf(file, "        \"percentage\": %.2f\n", stat.Percentage)
		fmt.Fprintf(file, "      }%s\n", comma)
	}

	fmt.Fprintln(file, "    ],")

	if len(monthStats) > 0 {
		deadliest := monthStats[0]
		fmt.Fprintln(file, "    \"deadliest_month\": {")
		fmt.Fprintf(file, "      \"month\": \"%s\",\n", deadliest.Month)
		fmt.Fprintf(file, "      \"month_name\": \"%s\",\n", deadliest.MonthName)
		fmt.Fprintf(file, "      \"homicide_count\": %d\n", deadliest.Count)
		fmt.Fprintln(file, "    }")
	}

	fmt.Fprintln(file, "  }")
	fmt.Fprintln(file, "}")

	fmt.Println("✅ JSON file 'homicide_analysis.json' created successfully!")
}

func escapeJSON(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, "\"", "\\\"")
	s = strings.ReplaceAll(s, "\n", "\\n")
	s = strings.ReplaceAll(s, "\r", "\\r")
	s = strings.ReplaceAll(s, "\t", "\\t")
	return s
}