package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/PuerkitoBio/goquery"
)

type Homicide struct {
	Date       string `json:"date"`
	Location   string `json:"location"`
	Status     string `json:"status"`
	VictimName string `json:"victim_name"`
}

type QA struct {
	Question string `json:"question"`
	Answer   string `json:"answer"`
}

func main() {
	outputFlag := flag.String("output", "", "Output format: csv, json, or leave empty for stdout")
	flag.Parse()

	url := "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
	homicides, err := scrapeHomicides(url)
	if err != nil {
		log.Fatalf("Failed to scrape data: %v", err)
	}

	streetCount := map[string]int{}
	closedCount := 0

	for _, h := range homicides {
		street := strings.Split(h.Location, ",")[0] // crude street extraction
		streetCount[street]++
		if strings.ToLower(h.Status) == "closed" {
			closedCount++
		}
	}

	// Find street with highest homicides
	var maxStreet string
	maxCount := 0
	for street, count := range streetCount {
		if count > maxCount {
			maxStreet = street
			maxCount = count
		}
	}

	qaList := []QA{
		{"Question 1: Name one street with one of the highest number of homicide cases?", maxStreet},
		{"Question 2: What is total number of homicide cases that have been closed?", fmt.Sprintf("%d", closedCount)},
		{"Question 3: What is the total number of homicide cases?", fmt.Sprintf("%d", len(homicides))},
	}

	switch strings.ToLower(*outputFlag) {
	case "csv":
		writeCSV(qaList)
	case "json":
		writeJSON(qaList)
	default:
		for _, qa := range qaList {
			fmt.Printf("%s %s\n", qa.Question, qa.Answer)
		}
	}
}

func scrapeHomicides(url string) ([]Homicide, error) {
	res, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()

	if res.StatusCode != 200 {
		return nil, fmt.Errorf("HTTP error: %d %s", res.StatusCode, res.Status)
	}

	doc, err := goquery.NewDocumentFromReader(res.Body)
	if err != nil {
		return nil, err
	}

	var homicides []Homicide
	doc.Find("table tbody tr").Each(func(i int, s *goquery.Selection) {
		var h Homicide
		s.Find("td").Each(func(j int, td *goquery.Selection) {
			text := strings.TrimSpace(td.Text())
			switch j {
			case 0:
				h.Date = text
			case 1:
				h.VictimName = text
			case 2:
				h.Location = text
			case 3:
				h.Status = text
			}
		})
		if h.Date != "" {
			homicides = append(homicides, h)
		}
	})

	return homicides, nil
}

func writeCSV(qaList []QA) {
	file, err := os.Create("output.csv")
	if err != nil {
		log.Fatalf("Cannot create CSV file: %v", err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"Question", "Answer"})
	for _, qa := range qaList {
		writer.Write([]string{qa.Question, qa.Answer})
	}

	fmt.Println("CSV file written to output.csv")
	for _, qa := range qaList {
		fmt.Printf("%s %s\n", qa.Question, qa.Answer)
	}
}

func writeJSON(qaList []QA) {
	file, err := os.Create("output.json")
	if err != nil {
		log.Fatalf("Cannot create JSON file: %v", err)
	}
	defer file.Close()

	enc := json.NewEncoder(file)
	enc.SetIndent("", "  ")
	err = enc.Encode(qaList)
	if err != nil {
		log.Fatalf("Error encoding JSON: %v", err)
	}

	fmt.Println("JSON file written to output.json")
	for _, qa := range qaList {
		fmt.Printf("%s %s\n", qa.Question, qa.Answer)
	}
}
