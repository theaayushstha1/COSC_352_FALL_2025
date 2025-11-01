package main

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/PuerkitoBio/goquery"
)

type Incident struct {
	Name     string `json:"name"`
	Age      string `json:"age"`
	Gender   string `json:"gender"`
	Race     string `json:"race"`
	Date     string `json:"date"`
	Cause    string `json:"cause"`
	Weapon   string `json:"weapon"`
	District string `json:"district"`
	Location string `json:"location"`
}

type Statistics struct {
	Total      int            `json:"total"`
	ByGender   map[string]int `json:"byGender"`
	ByRace     map[string]int `json:"byRace"`
	ByDistrict map[string]int `json:"byDistrict"`
}

func fetchYear(year int) []Incident {
	url := getURLForYear(year)
	fmt.Printf("🔎 Fetching: %s\n", url)

	client := &http.Client{
		Timeout: 30 * time.Second,
		Transport: &http.Transport{
			MaxIdleConns:        10,
			IdleConnTimeout:     30 * time.Second,
			DisableCompression:  false,
		},
	}

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		fmt.Printf("⚠️ Failed to create request for %d: %v\n", year, err)
		return nil
	}

	// Set headers to mimic a real browser
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
	req.Header.Set("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")

	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("⚠️ Failed to fetch data for %d: %v\n", year, err)
		return nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		fmt.Printf("⚠️ HTTP %d for %d: %s\n", resp.StatusCode, year, resp.Status)
		return nil
	}

	doc, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		fmt.Printf("⚠️ Failed to parse HTML for %d: %v\n", year, err)
		return nil
	}

	var incidents []Incident
	doc.Find("table tr").Each(func(i int, row *goquery.Selection) {
		if i == 0 {
			return // Skip header row
		}

		var cols []string
		row.Find("td").Each(func(j int, col *goquery.Selection) {
			cols = append(cols, strings.TrimSpace(col.Text()))
		})

		if len(cols) >= 9 {
			incident := Incident{
				Name:     safeString(cols[0]),
				Age:      safeString(cols[1]),
				Gender:   safeString(cols[2]),
				Race:     safeString(cols[3]),
				Date:     safeString(cols[4]),
				Cause:    safeString(cols[5]),
				Weapon:   safeString(cols[6]),
				District: safeString(cols[7]),
				Location: safeString(cols[8]),
			}
			incidents = append(incidents, incident)
		}
	})

	fmt.Printf("✅ Fetched %d incidents for %d\n", len(incidents), year)
	return incidents
}

func safeString(s string) string {
	return strings.TrimSpace(s)
}

func getURLForYear(year int) string {
	urls := map[int]string{
		2025: "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html",
		2024: "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
		2023: "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
		2022: "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
		2021: "https://chamspage.blogspot.com/2021/01/2021-baltimore-city-homicides-list.html",
		2020: "https://chamspage.blogspot.com/2020/01/2020-baltimore-city-homicides-list.html",
	}
	
	if url, exists := urls[year]; exists {
		return url
	}
	return fmt.Sprintf("https://chamspage.blogspot.com/%d/", year)
}

func analyze(incidents []Incident) Statistics {
	stats := Statistics{
		ByGender:   make(map[string]int),
		ByRace:     make(map[string]int),
		ByDistrict: make(map[string]int),
	}

	stats.Total = len(incidents)
	
	for _, incident := range incidents {
		stats.ByGender[incident.Gender]++
		stats.ByRace[incident.Race]++
		stats.ByDistrict[incident.District]++
	}

	return stats
}

func writeJSON(stats Statistics, filename string) error {
	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("failed to create file: %w", err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	
	if err := encoder.Encode(stats); err != nil {
		return fmt.Errorf("failed to encode JSON: %w", err)
	}

	fmt.Printf("💾 JSON saved as %s\n", filename)
	return nil
}

func writeCSV(incidents []Incident, filename string) error {
	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("failed to create file: %w", err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Write header
	header := []string{"Name", "Age", "Gender", "Race", "Date", "Cause", "Weapon", "District", "Location"}
	if err := writer.Write(header); err != nil {
		return fmt.Errorf("failed to write header: %w", err)
	}

	// Write data
	for _, incident := range incidents {
		record := []string{
			incident.Name,
			incident.Age,
			incident.Gender,
			incident.Race,
			incident.Date,
			incident.Cause,
			incident.Weapon,
			incident.District,
			incident.Location,
		}
		if err := writer.Write(record); err != nil {
			return fmt.Errorf("failed to write record: %w", err)
		}
	}

	fmt.Printf("💾 CSV saved as %s\n", filename)
	return nil
}

func printStats(stats Statistics) {
	fmt.Printf("📊 Total incidents: %d\n", stats.Total)
	
	fmt.Println("\nBy Gender:")
	for gender, count := range stats.ByGender {
		fmt.Printf("  %-10s -> %d\n", gender, count)
	}
	
	fmt.Println("\nBy Race:")
	for race, count := range stats.ByRace {
		fmt.Printf("  %-10s -> %d\n", race, count)
	}
	
	fmt.Println("\nBy District:")
	for district, count := range stats.ByDistrict {
		fmt.Printf("  %-10s -> %d\n", district, count)
	}
}

func main() {
	fmt.Println("🕵️ Baltimore Homicide Analysis Started (Go Version)")
	fmt.Println("===================================================")

	years := []int{2025, 2024, 2023}
	var allIncidents []Incident

	for _, year := range years {
		incidents := fetchYear(year)
		allIncidents = append(allIncidents, incidents...)
	}

	if len(allIncidents) == 0 {
		fmt.Println("❌ No incidents fetched. Exiting.")
		return
	}

	fmt.Printf("\n📈 Successfully collected %d total incidents\n", len(allIncidents))
	stats := analyze(allIncidents)

	// Check command line arguments
	args := os.Args[1:]
	outputJSON := false
	outputCSV := false

	for _, arg := range args {
		switch arg {
		case "--output=json":
			outputJSON = true
		case "--output=csv":
			outputCSV = true
		}
	}

	if outputJSON {
		if err := writeJSON(stats, "baltimore_output.json"); err != nil {
			log.Printf("❌ Error writing JSON: %v", err)
		}
	} else if outputCSV {
		if err := writeCSV(allIncidents, "baltimore_output.csv"); err != nil {
			log.Printf("❌ Error writing CSV: %v", err)
		}
	} else {
		printStats(stats)
	}

	fmt.Println("\n✅ Analysis complete.")
}