package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

type Row struct {
	DateStr   string // MM/DD/YY
	IsClosed  bool
}

var years = []string{"2024", "2025"}

func urlFor(year string) string {
	return fmt.Sprintf("https://chamspage.blogspot.com/%s/01/%s-baltimore-city-homicide-list.html", year, year)
}

func fetch(url string) (string, error) {
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("User-Agent", "Mozilla/5.0 (compatible; Project6-Go/1.0)")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return "", fmt.Errorf("HTTP %d fetching %s", resp.StatusCode, url)
	}
	b, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

func stripHTML(s string) string {
	// remove scripts/styles
	reScr := regexp.MustCompile(`(?is)<script.*?</script>`)
	reSty := regexp.MustCompile(`(?is)<style.*?</style>`)
	s = reScr.ReplaceAllString(s, " ")
	s = reSty.ReplaceAllString(s, " ")
	// remove tags
	reTag := regexp.MustCompile(`<[^>]+>`)
	s = reTag.ReplaceAllString(s, " ")
	s = strings.ReplaceAll(s, "&nbsp;", " ")
	// collapse whitespace
	reWS := regexp.MustCompile(`\s+`)
	s = reWS.ReplaceAllString(s, " ")
	return strings.TrimSpace(s)
}

func parseRows(html string) []Row {
	text := stripHTML(html)

	// Similar heuristic as Scala: match "<num> MM/DD/YY"
	reEntry := regexp.MustCompile(`(?:^|\s)(\d{1,3})\s+(\d{2}/\d{2}/\d{2})`)
	locs := reEntry.FindAllStringSubmatchIndex(text, -1)

	rows := make([]Row, 0, len(locs))
	for _, idx := range locs {
		// idx = [fullStart fullEnd g1Start g1End g2Start g2End]
		date := text[idx[4]:idx[5]]
		// look ahead a bit for 'Closed'
		tailStart := idx[5]
		tailEnd := tailStart + 250
		if tailEnd > len(text) {
			tailEnd = len(text)
		}
		tail := text[tailStart:tailEnd]
		isClosed := strings.Contains(strings.ToLower(tail), "closed")
		rows = append(rows, Row{DateStr: date, IsClosed: isClosed})
	}
	return rows
}

var monthNames = []string{
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December",
}

func monthName(mm string) string {
	switch mm {
	case "01":
		return "January"
	case "02":
		return "February"
	case "03":
		return "March"
	case "04":
		return "April"
	case "05":
		return "May"
	case "06":
		return "June"
	case "07":
		return "July"
	case "08":
		return "August"
	case "09":
		return "September"
	case "10":
		return "October"
	case "11":
		return "November"
	case "12":
		return "December"
	default:
		return "Unknown"
	}
}

func monthlyCountsFor(year string) ([][2]interface{}, int, error) {
	html, err := fetch(urlFor(year))
	if err != nil {
		return nil, 0, err
	}
	rows := parseRows(html)

	counts := make(map[string]int)
	for _, m := range monthNames {
		counts[m] = 0
	}
	for _, r := range rows {
		if len(r.DateStr) >= 2 {
			mn := monthName(r.DateStr[:2])
			if _, ok := counts[mn]; ok {
				counts[mn]++
			}
		}
	}
	// sort desc by count
	type kv struct{ Month string; Count int }
	arr := make([]kv, 0, 12)
	total := 0
	for m, c := range counts {
		arr = append(arr, kv{m, c})
		total += c
	}
	sort.Slice(arr, func(i, j int) bool {
		if arr[i].Count == arr[j].Count {
			return arr[i].Month < arr[j].Month
		}
		return arr[i].Count > arr[j].Count
	})
	out := make([][2]interface{}, 0, len(arr))
	for _, e := range arr {
		if e.Count > 0 {
			out = append(out, [2]interface{}{e.Month, e.Count})
		}
	}
	return out, total, nil
}

type Closure struct {
	Year      string  `json:"year"`
	Closed    int     `json:"closed"`
	Open      int     `json:"open"`
	Total     int     `json:"total"`
	ClosedPct float64 `json:"closedPct"`
}

func closure2024() (Closure, error) {
	year := "2024"
	html, err := fetch(urlFor(year))
	if err != nil {
		return Closure{}, err
	}
	rows := parseRows(html)
	closed := 0
	for _, r := range rows {
		if r.IsClosed {
			closed++
		}
	}
	total := len(rows)
	open := total - closed
	pct := 0.0
	if total > 0 {
		pct = float64(closed) * 100.0 / float64(total)
	}
	return Closure{Year: year, Closed: closed, Open: open, Total: total, ClosedPct: pct}, nil
}

// ---------- Output builders ----------

func toCSV(monthly map[string][][2]interface{}, closure Closure) string {
	var b strings.Builder
	b.WriteString("section,year,field,value\n")
	for y, arr := range monthly {
		for _, pair := range arr {
			month := pair[0].(string)
			count := pair[1].(int)
			b.WriteString(fmt.Sprintf("monthly,%s,%s,%d\n", y, month, count))
		}
	}
	b.WriteString(fmt.Sprintf("closure,%s,Closed,%d\n", closure.Year, closure.Closed))
	b.WriteString(fmt.Sprintf("closure,%s,Open,%d\n", closure.Year, closure.Open))
	return b.String()
}

func toJSON(monthly map[string][][2]interface{}, closure Closure) string {
	obj := map[string]interface{}{
		"monthlyByYear": monthly,
		"closure2024":   closure,
	}
	data, _ := json.Marshal(obj)
	return string(data)
}

func writeFile(name, content string) (string, error) {
	// Prefer /out (mounted) if present
	targetDir := "/out"
	if st, err := os.Stat(targetDir); err != nil || !st.IsDir() {
		targetDir = "."
	}
	path := filepath.Join(targetDir, name)
	err := os.WriteFile(path, []byte(content), 0644)
	return path, err
}

func main() {
	// Parse flag: --output=csv|json (default stdout)
	format := "stdout"
	for _, a := range os.Args[1:] {
		if strings.HasPrefix(a, "--output=") {
			format = strings.ToLower(strings.TrimPrefix(a, "--output="))
		}
	}

	// Build results
	monthly := make(map[string][][2]interface{})
	totalsByYear := make(map[string]int)
	for _, y := range years {
		arr, total, err := monthlyCountsFor(y)
		if err != nil {
			fmt.Fprintf(os.Stderr, "error: %v\n", err)
			os.Exit(1)
		}
		monthly[y] = arr
		totalsByYear[y] = total
	}
	closure, err := closure2024()
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	switch format {
	case "csv":
		csv := toCSV(monthly, closure)
		path, err := writeFile("project6_output.csv", csv)
		if err != nil {
			fmt.Printf("failed to write CSV: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("CSV written to %s\n", path)

	case "json":
		jsonStr := toJSON(monthly, closure)
		path, err := writeFile("project6_output.json", jsonStr)
		if err != nil {
			fmt.Printf("failed to write JSON: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("JSON written to %s\n", path)

	default:
		fmt.Println("Question 1: Between 2024 and 2025, which months had the highest number of homicides?")
		for _, y := range years {
			fmt.Printf("\n%s:\n", y)
			fmt.Printf("%-12s | %s\n", "Month", "Count")
			fmt.Println("----------------------")
			sum := 0
			for _, pair := range monthly[y] {
				fmt.Printf("%-12s | %5d\n", pair[0].(string), pair[1].(int))
				sum += pair[1].(int)
			}
			fmt.Printf("Total homicides recorded: %d\n", totalsByYear[y])
		}
		fmt.Printf("\nQuestion 2: In 2024, how many homicide cases are marked 'Closed' vs 'Open'?\n")
		openPct := 100.0 - closure.ClosedPct
		fmt.Printf("%-6s | %-5s | %s\n", "Status", "Count", "Share")
		fmt.Println("----------------------")
		fmt.Printf("Closed  | %5d | %.1f%%\n", closure.Closed, closure.ClosedPct)
		fmt.Printf("Open    | %5d | %.1f%%\n", closure.Open, openPct)
		fmt.Printf("Total cases analyzed: %d\n", closure.Total)
	}
}
