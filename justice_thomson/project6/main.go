package main

import (
	"fmt"
	"io"
	"math"
	"net/http"
	"os"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"encoding/json"
)

func main() {
	args := os.Args
	outputOpt := ""
	if len(args) > 1 && strings.HasPrefix(args[1], "--output=") {
		outputOpt = strings.ToLower(strings.Split(args[1], "=")[1])
	}

	url := "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
	resp, err := http.Get(url)
	if err != nil {
		fmt.Printf("Error fetching URL: %v\n", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Printf("Error reading response: %v\n", err)
		os.Exit(1)
	}
	html := string(body)

	// Strip tags and normalize whitespace
	noTagsRe := regexp.MustCompile(`<[^>]+>`)
	noTags := noTagsRe.ReplaceAllString(html, "")
	normalized := strings.ReplaceAll(noTags, "\r", "")
	spaceRe := regexp.MustCompile(`\s+`)
	normalized = spaceRe.ReplaceAllString(normalized, " ")

	// Truncate at footer marker
	footerStart := strings.Index(normalized, "Post a Comment")
	cleanText := normalized
	if footerStart != -1 {
		cleanText = strings.TrimSpace(normalized[:footerStart])
	}

	// Patterns
	pattern := regexp.MustCompile(`(\d{3}|XXX|\?\?\?)\s+(\d{2}/\d{2}/\d{2})\b`)
	cameraRe := regexp.MustCompile(`(?i)\b\d+\s*cameras?\b`)
	closedRe := regexp.MustCompile(`(?i)\bclosed\b`)

	// Find all matches with indices
	matches := pattern.FindAllStringSubmatchIndex(cleanText, -1)

	type Entry struct {
		Number      string
		Date        string
		Month       int
		HasCamera   bool
		IsClosed    bool
		Description string
	}

	var entries []Entry
	for i := 0; i < len(matches); i++ {
		m := matches[i]
		start := m[0]
		end := len(cleanText)
		if i+1 < len(matches) {
			end = matches[i+1][0]
		}
		line := strings.TrimSpace(cleanText[start:end])
		number := cleanText[m[2]:m[3]]
		date := cleanText[m[4]:m[5]]
		if !strings.HasSuffix(date, "/25") {
			continue
		}
		month, err := strconv.Atoi(date[:2])
		if err != nil {
			continue
		}
		matchedLen := m[1] - m[0]
		description := strings.TrimSpace(line[matchedLen:])
		hasCam := cameraRe.MatchString(line)
		isClosed := closedRe.MatchString(line)
		entries = append(entries, Entry{
			Number:      number,
			Date:        date,
			Month:       month,
			HasCamera:   hasCam,
			IsClosed:    isClosed,
			Description: description,
		})
	}

	// Compute aggregates
	months := []string{"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
	byMonth := make(map[int]int)
	for _, e := range entries {
		byMonth[e.Month]++
	}
	var monthlyCounts [][]interface{}
	for m := 1; m <= 12; m++ {
		count := byMonth[m]
		monthlyCounts = append(monthlyCounts, []interface{}{months[m-1], count})
	}

	total := len(entries)
	withCam := 0
	for _, e := range entries {
		if e.HasCamera {
			withCam++
		}
	}
	withoutCam := total - withCam
	closedWith := 0
	for _, e := range entries {
		if e.HasCamera && e.IsClosed {
			closedWith++
		}
	}
	closedWithout := 0
	for _, e := range entries {
		if !e.HasCamera && e.IsClosed {
			closedWithout++
		}
	}

	pct := func(n, d int) string {
		if d == 0 {
			return "0%"
		}
		p := float64(n) / float64(d) * 100
		return fmt.Sprintf("%.1f%%", math.Round(p*10)/10)
	}

	closureStats := map[string]string{
		"total_incidents":             fmt.Sprint(total),
		"with_cameras":                fmt.Sprint(withCam),
		"closed_with_cameras":         fmt.Sprint(closedWith),
		"closed_with_cameras_pct":     pct(closedWith, withCam),
		"without_cameras":             fmt.Sprint(withoutCam),
		"closed_without_cameras":      fmt.Sprint(closedWithout),
		"closed_without_cameras_pct":  pct(closedWithout, withoutCam),
	}

	switch outputOpt {
	case "csv":
		file, err := os.Create("/app/output/data.csv")
		if err != nil {
			fmt.Printf("Error creating CSV file: %v\n", err)
			os.Exit(1)
		}
		defer file.Close()
		fmt.Fprintln(file, "Question 1: How many homicides occurred in each month of 2025?")
		fmt.Fprintln(file, "month,count")
		for _, mc := range monthlyCounts {
			fmt.Fprintf(file, "\"%s\",%d\n", mc[0], mc[1])
		}
		fmt.Fprintln(file, "")
		fmt.Fprintln(file, "Question 2: What is the closure rate for incidents with and without surveillance cameras in 2025?")
		fmt.Fprintln(file, "metric,value")
		// Sort keys for consistent order
		keys := make([]string, 0, len(closureStats))
		for k := range closureStats {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		for _, k := range keys {
			v := closureStats[k]
			fmt.Fprintf(file, "\"%s\",\"%s\"\n", k, v)
		}

	case "json":
		type Monthly struct {
			Month string `json:"month"`
			Count int    `json:"count"`
		}
		var mj []Monthly
		for _, mc := range monthlyCounts {
			mj = append(mj, Monthly{Month: mc[0].(string), Count: mc[1].(int)})
		}
		data := map[string]interface{}{
			"question1": mj,
			"question2": closureStats,
		}
		jsonData, err := json.Marshal(data)
		if err != nil {
			fmt.Printf("Error marshaling JSON: %v\n", err)
			os.Exit(1)
		}
		err = os.WriteFile("/app/output/data.json", jsonData, 0644)
		if err != nil {
			fmt.Printf("Error writing JSON file: %v\n", err)
			os.Exit(1)
		}

	default:
		fmt.Println("Question 1: How many homicides occurred in each month of 2025?")
		for _, mc := range monthlyCounts {
			fmt.Printf("%s: %d\n", mc[0], mc[1])
		}
		fmt.Println("\nQuestion 2: What is the closure rate for incidents with and without surveillance cameras in 2025?")
		fmt.Printf("Total parsed incidents: %d\n", total)
		fmt.Printf("With cameras: %d, Closed with cameras: %d (%s)\n", withCam, closedWith, pct(closedWith, withCam))
		fmt.Printf("Without cameras: %d, Closed without cameras: %d (%s)\n", withoutCam, closedWithout, pct(closedWithout, withoutCam))
	}
}