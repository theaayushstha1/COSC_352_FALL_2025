package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/PuerkitoBio/goquery"
)

type HomicideCase struct {
	Date       string `json:"date"`
	Name       string `json:"name"`
	Age        int    `json:"age"`
	Address    string `json:"address"`
	CaseClosed string `json:"caseClosed"`
}

func main() {
	// Parse flags
	outputFlag := flag.String("output", "stdout", "Output format: stdout, csv, json")
	flag.Parse()
	outputFormat := strings.ToLower(*outputFlag)

	url := "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"

	// Fetch HTML
	resp, err := http.Get(url)
	if err != nil {
		log.Fatalf("❌ Failed to fetch URL: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		log.Fatalf("❌ Non-200 response: %d", resp.StatusCode)
	}

	doc, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		log.Fatalf("❌ Failed to parse HTML: %v", err)
	}

	// Parse table rows
	var homicideCases []HomicideCase
	doc.Find("table tr").Each(func(i int, row *goquery.Selection) {
		if i == 0 {
			return // skip header
		}
		cells := row.Find("td").Map(func(_ int, s *goquery.Selection) string {
			return strings.TrimSpace(s.Text())
		})
		if len(cells) >= 5 {
			age, _ := strconv.Atoi(cells[3])
			homicideCases = append(homicideCases, HomicideCase{
				Date:       cells[1],
				Name:       cells[2],
				Age:        age,
				Address:    cells[4],
				CaseClosed: cells[len(cells)-1],
			})
		}
	})

	// Analytics: top street
	streetCount := map[string]int{}
	re := regexp.MustCompile(`(?i)\b(block|blk|unit)\b|\d+`)
	for _, h := range homicideCases {
		street := strings.TrimSpace(re.ReplaceAllString(h.Address, ""))
		street = regexp.MustCompile(`\s+`).ReplaceAllString(street, " ")
		if street != "" {
			streetCount[street]++
		}
	}

	type kv struct {
		Key   string
		Value int
	}
	var sortedStreets []kv
	for k, v := range streetCount {
		sortedStreets = append(sortedStreets, kv{k, v})
	}
	sort.Slice(sortedStreets, func(i, j int) bool {
		return sortedStreets[i].Value > sortedStreets[j].Value
	})

	topStreet := "No street data found."
	if len(sortedStreets) > 0 {
		topStreet = fmt.Sprintf("%s : %d cases", sortedStreets[0].Key, sortedStreets[0].Value)
	}

	// Count closed cases
	closedCases := 0
	for _, h := range homicideCases {
		if strings.EqualFold(h.CaseClosed, "Closed") {
			closedCases++
		}
	}

	// Host path for output files
	outputDir := "/app" // container path mapped to host
	csvFile := fmt.Sprintf("%s/output.csv", outputDir)
	jsonFile := fmt.Sprintf("%s/output.json", outputDir)

	// Output
	switch outputFormat {
	case "stdout":
		fmt.Println("Fetching Baltimore Homicide Statistics...\n")
		fmt.Println("---- RAW HOMICIDE DATA ----")
		for _, h := range homicideCases {
			fmt.Printf("%s | %s | %d | %s | %s\n", h.Date, h.Name, h.Age, h.Address, h.CaseClosed)
		}
		fmt.Println("----------------------------\n")
		fmt.Println("===== Baltimore Homicide Analysis =====")
		fmt.Println("Name one street with highest number of homicide cases:", topStreet)
		fmt.Println("What is the total number of closed homicide cases:", closedCases)
		fmt.Println("=======================================")

	case "csv":
		file, err := os.Create(csvFile)
		if err != nil {
			log.Fatalf("❌ Failed to create CSV: %v", err)
		}
		defer file.Close()
		writer := csv.NewWriter(file)
		defer writer.Flush()
		writer.Write([]string{"Date", "Name", "Age", "Address", "CaseClosed"})
		for _, h := range homicideCases {
			writer.Write([]string{h.Date, h.Name, strconv.Itoa(h.Age), h.Address, h.CaseClosed})
		}
		fmt.Printf("✅ CSV data written to %s\n", csvFile)

	case "json":
		file, err := os.Create(jsonFile)
		if err != nil {
			log.Fatalf("❌ Failed to create JSON: %v", err)
		}
		defer file.Close()
		enc := json.NewEncoder(file)
		enc.SetIndent("", "  ")
		err = enc.Encode(homicideCases)
		if err != nil {
			log.Fatalf("❌ Failed to write JSON: %v", err)
		}
		fmt.Printf("✅ JSON data written to %s\n", jsonFile)

	default:
		fmt.Printf("⚠️ Unknown output format '%s'. Defaulting to stdout.\n", outputFormat)
	}
}
