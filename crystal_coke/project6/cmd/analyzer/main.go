package main

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"strings"
)

type HomicideRecord struct {
	Number     string `json:"number"`
	DateDied   string `json:"dateDied"`
	Name       string `json:"name"`
	Age        string `json:"age"`
	Address    string `json:"address"`
	Notes      string `json:"notes"`
	CaseClosed string `json:"caseClosed"`
}

func main() {
	outputType := "stdout"
	if len(os.Args) > 1 {
		outputType = os.Args[1]
	}

	fmt.Println(strings.Repeat("=", 80))
	fmt.Println("Baltimore City Homicide Statistics Analysis - 2025 Data")
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println()

	url := "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"

	records, err := fetchAndAnalyzeData(url)
	if err != nil {
		fmt.Println("❌ Error fetching data:", err)
		os.Exit(1)
	}

	records2025 := filterYear(records, "2025")
	closedCases := countClosedCases(records2025)
	shootingVictims := countShootingVictims(records2025)

	summary := fmt.Sprintf(
		"Total records analyzed for 2025: %d\nClosed cases: %d\nShooting victims: %d",
		len(records2025), closedCases, shootingVictims)

	switch outputType {
	case "csv":
		if err := writeToCSV(records2025); err != nil {
			fmt.Println("Error writing CSV:", err)
		} else {
			fmt.Println("✅ Output written to output.csv")
		}
	case "json":
		if err := writeToJSON(records2025); err != nil {
			fmt.Println("Error writing JSON:", err)
		} else {
			fmt.Println("✅ Output written to output.json")
		}
	default:
		fmt.Println(summary)
		fmt.Println(strings.Repeat("=", 80))
		fmt.Println("Analysis complete.")
		fmt.Println(strings.Repeat("=", 80))
	}
}

// --- Fetch and parse ---

func fetchAndAnalyzeData(url string) ([]HomicideRecord, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	return parseHtmlTable(string(body)), nil
}

func parseHtmlTable(html string) []HomicideRecord {
	rows := strings.Split(html, "<tr")
	var records []HomicideRecord

	tdPattern := regexp.MustCompile(`(?i)<td[^>]*>(.*?)</td>`)

	for _, row := range rows {
		matches := tdPattern.FindAllStringSubmatch(row, -1)
		if len(matches) > 0 {
			first := clean(matches[0][1])
			if matched, _ := regexp.MatchString(`^\d+.*`, first); matched {
				cells := []string{}
				for _, m := range matches {
					cells = append(cells, clean(m[1]))
				}
				for len(cells) < 8 {
					cells = append(cells, "")
				}
				record := HomicideRecord{
					Number:     cells[0],
					DateDied:   cells[1],
					Name:       cells[2],
					Age:        cells[3],
					Address:    cells[4],
					Notes:      cells[5],
					CaseClosed: cells[len(cells)-1],
				}
				records = append(records, record)
			}
		}
	}
	return records
}

func clean(text string) string {
	replacements := []struct{ old, new string }{
		{"&nbsp;", " "}, {"&amp;", "&"}, {"&#x27;", "'"},
	}
	for _, r := range replacements {
		text = strings.ReplaceAll(text, r.old, r.new)
	}
	re := regexp.MustCompile(`<[^>]+>`)
	text = re.ReplaceAllString(text, " ")
	reSpace := regexp.MustCompile(`\s+`)
	return strings.TrimSpace(reSpace.ReplaceAllString(text, " "))
}

// --- Filters and counts ---

func filterYear(records []HomicideRecord, year string) []HomicideRecord {
	shortYear := year[len(year)-2:]
	var filtered []HomicideRecord
	for _, r := range records {
		if strings.Contains(r.DateDied, year) || strings.Contains(r.DateDied, shortYear) {
			filtered = append(filtered, r)
		}
	}
	return filtered
}

func countClosedCases(records []HomicideRecord) int {
	count := 0
	for _, r := range records {
		if strings.Contains(strings.ToLower(r.CaseClosed), "closed") {
			count++
		}
	}
	return count
}

func countShootingVictims(records []HomicideRecord) int {
	count := 0
	for _, r := range records {
		notes := strings.ToLower(r.Notes)
		if strings.Contains(notes, "shoot") || strings.Contains(notes, "gunshot") {
			count++
		}
	}
	return count
}

// --- Outputs ---

func writeToCSV(records []HomicideRecord) error {
	f, err := os.Create("output.csv")
	if err != nil {
		return err
	}
	defer f.Close()

	writer := csv.NewWriter(f)
	defer writer.Flush()

	writer.Write([]string{"Number", "DateDied", "Name", "Age", "Address", "Notes", "CaseClosed"})
	for _, r := range records {
		writer.Write([]string{r.Number, r.DateDied, r.Name, r.Age, r.Address, r.Notes, r.CaseClosed})
	}
	return nil
}

func writeToJSON(records []HomicideRecord) error {
	f, err := os.Create("output.json")
	if err != nil {
		return err
	}
	defer f.Close()
	enc := json.NewEncoder(f)
	enc.SetIndent("", "  ")
	return enc.Encode(records)
}
