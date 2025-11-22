package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"strings"
)

type AnalysisResult struct {
	Total           int
	Stabbing        int
	Shooting        int
	Other           int
	Violent         int
	Closed          int
	StabbingClosed  int
	ShootingClosed  int
}

func main() {
	outputFormat := "stdout"
	if len(os.Args) > 1 {
		outputFormat = strings.ToLower(os.Args[1])
	}

	url := "https://chamspage.blogspot.com/"
	fmt.Printf("Fetching data from: %s\n", url)

	html, err := fetchURL(url)
	if err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: Failed to fetch URL: %v\n", err)
		os.Exit(1)
	}

	tableHTML, err := extractBestTable(html)
	if err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: Could not find a suitable table on the page.\n")
		os.Exit(2)
	}

	rows := parseTableRows(tableHTML)
	if len(rows) == 0 {
		fmt.Fprintf(os.Stderr, "ERROR: No rows parsed from the table.\n")
		os.Exit(2)
	}

	header := rows[0]
	dataRows := rows[1:]

	weaponIdx := findColumnIndex(header, []string{"weapon", "method", "manner", "type", "cause"})
	statusIdx := findColumnIndex(header, []string{"status", "case", "disposition", "investigation", "cleared"})

	result := analyzeData(dataRows, weaponIdx, statusIdx)

	switch outputFormat {
	case "csv":
		outputCSV(result)
	case "json":
		outputJSON(result)
	default:
		outputStdout(result)
	}
}

func fetchURL(url string) (string, error) {
	client := &http.Client{}
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", "GoHomicideParser/1.0")

	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return string(body), nil
}

func extractBestTable(html string) (string, error) {
	re := regexp.MustCompile(`(?s)<table.*?>.*?</table>`)
	matches := re.FindAllString(html, -1)
	
	if len(matches) == 0 {
		return "", fmt.Errorf("no tables found")
	}

	// Find the longest table
	longest := matches[0]
	for _, match := range matches {
		if len(match) > len(longest) {
			longest = match
		}
	}

	return longest, nil
}

func parseTableRows(tableHTML string) [][]string {
	rowRe := regexp.MustCompile(`(?s)<tr.*?>.*?</tr>`)
	cellRe := regexp.MustCompile(`(?s)<t[dh].*?>(.*?)</t[dh]>`)

	rowMatches := rowRe.FindAllString(tableHTML, -1)
	var rows [][]string

	for _, rowHTML := range rowMatches {
		cellMatches := cellRe.FindAllStringSubmatch(rowHTML, -1)
		var cells []string
		for _, match := range cellMatches {
			if len(match) > 1 {
				cells = append(cells, strings.TrimSpace(stripTags(match[1])))
			}
		}
		if len(cells) > 0 {
			rows = append(rows, cells)
		}
	}

	return rows
}

func stripTags(s string) string {
	re := regexp.MustCompile(`(?s)<.*?>`)
	s = re.ReplaceAllString(s, "")
	s = strings.ReplaceAll(s, "&nbsp;", " ")
	return s
}

func findColumnIndex(header []string, candidates []string) int {
	for i, h := range header {
		lowerH := strings.ToLower(h)
		for _, candidate := range candidates {
			if strings.Contains(lowerH, candidate) {
				return i
			}
		}
	}
	return -1
}

func safeGet(lst []string, idx int) string {
	if idx >= 0 && idx < len(lst) {
		return lst[idx]
	}
	return ""
}

func containsAny(s string, patterns []string) bool {
	for _, pattern := range patterns {
		if strings.Contains(s, pattern) {
			return true
		}
	}
	return false
}

func isClosed(status string) bool {
	return containsAny(status, []string{"closed", "cleared", "solved", "arrest", "charge"})
}

func analyzeData(dataRows [][]string, weaponIdx, statusIdx int) AnalysisResult {
	result := AnalysisResult{}

	for _, row := range dataRows {
		result.Total++

		var weaponRaw string
		if weaponIdx >= 0 && weaponIdx < len(row) {
			weaponRaw = strings.ToLower(row[weaponIdx])
		} else {
			weaponRaw = strings.ToLower(strings.Join(row, " "))
		}

		statusRaw := "unknown"
		if statusIdx >= 0 && statusIdx < len(row) {
			statusRaw = strings.ToLower(row[statusIdx])
		}

		isStab := containsAny(weaponRaw, []string{"stab", "knife", "stabbing"})
		isShoot := containsAny(weaponRaw, []string{"shoot", "shot", "gun", "firearm"})

		if isStab {
			result.Stabbing++
			if isClosed(statusRaw) {
				result.StabbingClosed++
			}
		} else if isShoot {
			result.Shooting++
			if isClosed(statusRaw) {
				result.ShootingClosed++
			}
		}
	}

	result.Other = result.Total - result.Stabbing - result.Shooting
	result.Violent = result.Stabbing + result.Shooting
	result.Closed = result.StabbingClosed + result.ShootingClosed

	return result
}

func percentage(part, total int) float64 {
	if total == 0 {
		return 0.0
	}
	return (float64(part) / float64(total)) * 100.0
}

func outputStdout(r AnalysisResult) {
	fmt.Println("\nQuestion 1: What is the ratio of stabbing victims and shooting victims compared to the total?\n")
	fmt.Printf("Total victims: %d\n", r.Total)
	if r.Total > 0 {
		fmt.Printf("Stabbing victims: %d (%.2f%%)\n", r.Stabbing, percentage(r.Stabbing, r.Total))
		fmt.Printf("Shooting victims: %d (%.2f%%)\n", r.Shooting, percentage(r.Shooting, r.Total))
		fmt.Printf("Other/Unclassified: %d (%.2f%%)\n", r.Other, percentage(r.Other, r.Total))
	}

	fmt.Println("\nQuestion 2: Of these victims (stabbing or shooting), what is the ratio of closed cases?\n")
	fmt.Printf("Total stabbing/shooting victims: %d\n", r.Violent)
	if r.Violent > 0 {
		fmt.Printf("Closed cases total: %d (%.2f%%)\n", r.Closed, percentage(r.Closed, r.Violent))
		stabbingPct := 0.0
		if r.Stabbing > 0 {
			stabbingPct = percentage(r.StabbingClosed, r.Stabbing)
		}
		shootingPct := 0.0
		if r.Shooting > 0 {
			shootingPct = percentage(r.ShootingClosed, r.Shooting)
		}
		fmt.Printf(" - Closed stabbing: %d of %d (%.2f%%)\n", r.StabbingClosed, r.Stabbing, stabbingPct)
		fmt.Printf(" - Closed shooting: %d of %d (%.2f%%)\n", r.ShootingClosed, r.Shooting, shootingPct)
	} else {
		fmt.Println("No stabbing or shooting victims detected.")
	}
}

func outputCSV(r AnalysisResult) {
	filename := determineOutputPath("homicide_analysis.csv")
	file, err := os.Create(filename)
	if err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: Failed to create CSV file: %v\n", err)
		return
	}
	defer file.Close()

	fmt.Fprintln(file, "category,subcategory,count,percentage,description")
	fmt.Fprintf(file, "total_victims,all,%d,100.00,Total number of victims\n", r.Total)
	fmt.Fprintf(file, "victim_type,stabbing,%d,%.2f,Victims of stabbing\n", r.Stabbing, percentage(r.Stabbing, r.Total))
	fmt.Fprintf(file, "victim_type,shooting,%d,%.2f,Victims of shooting\n", r.Shooting, percentage(r.Shooting, r.Total))
	fmt.Fprintf(file, "victim_type,other,%d,%.2f,Other/Unclassified victims\n", r.Other, percentage(r.Other, r.Total))
	fmt.Fprintf(file, "violent_crimes,total,%d,100.00,Total stabbing and shooting victims\n", r.Violent)
	fmt.Fprintf(file, "case_status,closed,%d,%.2f,Total closed cases (stabbing + shooting)\n", r.Closed, percentage(r.Closed, r.Violent))
	fmt.Fprintf(file, "case_status,open,%d,%.2f,Total open cases (stabbing + shooting)\n", r.Violent-r.Closed, percentage(r.Violent-r.Closed, r.Violent))

	stabbingPct := 0.0
	if r.Stabbing > 0 {
		stabbingPct = percentage(r.StabbingClosed, r.Stabbing)
	}
	shootingPct := 0.0
	if r.Shooting > 0 {
		shootingPct = percentage(r.ShootingClosed, r.Shooting)
	}

	fmt.Fprintf(file, "stabbing_status,closed,%d,%.2f,Closed stabbing cases\n", r.StabbingClosed, stabbingPct)
	fmt.Fprintf(file, "stabbing_status,open,%d,%.2f,Open stabbing cases\n", r.Stabbing-r.StabbingClosed, percentage(r.Stabbing-r.StabbingClosed, r.Stabbing))
	fmt.Fprintf(file, "shooting_status,closed,%d,%.2f,Closed shooting cases\n", r.ShootingClosed, shootingPct)
	fmt.Fprintf(file, "shooting_status,open,%d,%.2f,Open shooting cases\n", r.Shooting-r.ShootingClosed, percentage(r.Shooting-r.ShootingClosed, r.Shooting))

	fmt.Printf("CSV output written to: %s\n", filename)
}

func outputJSON(r AnalysisResult) {
	filename := determineOutputPath("homicide_analysis.json")
	file, err := os.Create(filename)
	if err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: Failed to create JSON file: %v\n", err)
		return
	}
	defer file.Close()

	stabbingPct := 0.0
	if r.Stabbing > 0 {
		stabbingPct = percentage(r.StabbingClosed, r.Stabbing)
	}
	shootingPct := 0.0
	if r.Shooting > 0 {
		shootingPct = percentage(r.ShootingClosed, r.Shooting)
	}

	output := map[string]interface{}{
		"analysis_metadata": map[string]interface{}{
			"source":                  "https://chamspage.blogspot.com/",
			"total_victims_analyzed": r.Total,
		},
		"question_1": map[string]interface{}{
			"question": "What is the ratio of stabbing victims and shooting victims compared to the total?",
			"total_victims": map[string]interface{}{
				"count":      r.Total,
				"percentage": 100.0,
			},
			"victim_breakdown": map[string]interface{}{
				"stabbing": map[string]interface{}{
					"count":      r.Stabbing,
					"percentage": percentage(r.Stabbing, r.Total),
				},
				"shooting": map[string]interface{}{
					"count":      r.Shooting,
					"percentage": percentage(r.Shooting, r.Total),
				},
				"other": map[string]interface{}{
					"count":      r.Other,
					"percentage": percentage(r.Other, r.Total),
				},
			},
		},
		"question_2": map[string]interface{}{
			"question": "Of these victims (stabbing or shooting), what is the ratio of closed cases?",
			"violent_crimes_total": map[string]interface{}{
				"count":      r.Violent,
				"percentage": 100.0,
			},
			"case_status_summary": map[string]interface{}{
				"closed": map[string]interface{}{
					"count":      r.Closed,
					"percentage": percentage(r.Closed, r.Violent),
				},
				"open": map[string]interface{}{
					"count":      r.Violent - r.Closed,
					"percentage": percentage(r.Violent-r.Closed, r.Violent),
				},
			},
			"detailed_breakdown": map[string]interface{}{
				"stabbing": map[string]interface{}{
					"total":              r.Stabbing,
					"closed":             r.StabbingClosed,
					"open":               r.Stabbing - r.StabbingClosed,
					"closed_percentage": stabbingPct,
				},
				"shooting": map[string]interface{}{
					"total":              r.Shooting,
					"closed":             r.ShootingClosed,
					"open":               r.Shooting - r.ShootingClosed,
					"closed_percentage": shootingPct,
				},
			},
		},
	}

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(output); err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: Failed to encode JSON: %v\n", err)
		return
	}

	fmt.Printf("JSON output written to: %s\n", filename)
}

func determineOutputPath(filename string) string {
	outputDir := "/output"
	if info, err := os.Stat(outputDir); err == nil && info.IsDir() {
		return outputDir + "/" + filename
	}
	return filename
}