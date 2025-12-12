package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"net/http"
	"os"
	"strings"

	"golang.org/x/net/html"
)

type HomicideData struct {
	Number         string `json:"number"`
	DateDied       string `json:"date_died"`
	Name           string `json:"name"`
	Age            string `json:"age"`
	AddressBlock   string `json:"address_block"`
	Notes          string `json:"notes"`
	ViolentHistory string `json:"violent_history"`
	Surveillance   string `json:"surveillance"`
	CaseClosed     string `json:"case_closed"`
}

func main() {
	// Parse flag
	outputFlag := flag.String("output", "", "Output format: csv or json")
	flag.Parse()

	url := "https://chamspage.blogspot.com/"

	// fetch table data
	homicides, err := fetchTableData(url)
	if err != nil {
		fmt.Println("Error fetching data:", err)
		os.Exit(1)
	}

	// compute stats
	avgAge := averageAgeInYear(homicides, 2025)
	surveillanceCount := countSurveillanceCasesInYear(homicides, 2025)


	switch strings.ToLower(*outputFlag) {
	case "":
		// Default stdout
		fmt.Printf("Question 1: What is the average age of victims in 2025?\n%.1f\n", avgAge)
		fmt.Printf("Question 2: How many of the cases in 2025 had surveillance cameras present at the location of the crime?\n%d\n", surveillanceCount)
	case "csv":
		if err := writeCSV(homicides, avgAge, surveillanceCount); err != nil {
			fmt.Println("Error writing CSV:", err)
			os.Exit(1)
		}
		fmt.Println("CSV wrote to BmoreHomicideStats.csv")
	case "json":
		if err := writeJSON(homicides, avgAge, surveillanceCount); err != nil {
			fmt.Println("Error writing JSON:", err)
			os.Exit(1)
		}
		fmt.Println("JSON written to BmoreHomicideStats.json")
	default:
		fmt.Println("Unknown output format:", *outputFlag)
		os.Exit(1)
	}
}

// fetch data
func fetchTableData(url string) ([]HomicideData, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	doc, err := html.Parse(resp.Body)
	if err != nil {
		return nil, err
	}

	var homicides []HomicideData
	var f func(*html.Node)
	f = func(n *html.Node) {
		if n.Type == html.ElementNode && n.Data == "tr" {
			cells := extractCells(n)
			if len(cells) >= 9 {
				h := HomicideData{
					Number:         cells[0],
					DateDied:       cells[1],
					Name:           cells[2],
					Age:            cells[3],
					AddressBlock:   cells[4],
					Notes:          cells[5],
					ViolentHistory: cells[6],
					Surveillance:   cells[7],
					CaseClosed:     cells[8],
				}
				homicides = append(homicides, h)
			}
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			f(c)
		}
	}
	f(doc)

	return homicides, nil
}

// extract text 
func extractCells(tr *html.Node) []string {
	var cells []string
	for c := tr.FirstChild; c != nil; c = c.NextSibling {
		if c.Type == html.ElementNode && c.Data == "td" {
			text := extractText(c)
			cells = append(cells, text)
		}
	}
	return cells
}

func extractText(n *html.Node) string {
	if n.Type == html.TextNode {
		return strings.TrimSpace(n.Data)
	}
	var result string
	for c := n.FirstChild; c != nil; c = c.NextSibling {
		result += extractText(c)
	}
	return strings.TrimSpace(result)
}

func averageAgeInYear(homicides []HomicideData, year int) float64 {
	var total, count int
	for _, h := range homicides {
		if extractYear(h.DateDied) == year {
			var age int
			fmt.Sscanf(h.Age, "%d", &age)
			if age > 0 {
				total += age
				count++
			}
		}
	}
	if count == 0 {
		return 0
	}
	return float64(total) / float64(count)
}

func countSurveillanceCasesInYear(homicides []HomicideData, year int) int {
	count := 0
	for _, h := range homicides {
		if extractYear(h.DateDied) == year && strings.Contains(strings.ToLower(h.Surveillance), "camera") {
			count++
		}
	}
	return count
}

func extractYear(date string) int {
	var month, day, yy int
	n, _ := fmt.Sscanf(date, "%d/%d/%d", &month, &day, &yy)
	if n == 3 {
		if yy >= 50 {
			return 1900 + yy
		}
		return 2000 + yy
	}
	return 0
}

func writeCSV(homicides []HomicideData, avgAge float64, surveillanceCount int) error {
	file, err := os.Create("BmoreHomicideStats.csv")
	if err != nil {
		return err
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{fmt.Sprintf("Average age of victims of Baltimore homicide in 2025,%.1f", avgAge)})
	writer.Write([]string{fmt.Sprintf("Cases in 2025 with cameras present at the scene,%d", surveillanceCount)})

	return nil
}

func writeJSON(homicides []HomicideData, avgAge float64, surveillanceCount int) error {
	file, err := os.Create("BmoreHomicideStats.json")
	if err != nil {
		return err
	}
	defer file.Close()

	data := map[string]interface{}{
		"average_age_2025":       avgAge,
		"surveillance_cases_2025": surveillanceCount,
	}

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	return encoder.Encode(data)
}
