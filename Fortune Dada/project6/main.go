package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"strings"
	"time"
)

type Incident struct {
	Year      int
	Number    int
	Address   string
	DateStr   string
	Name      string
	Age       *int
	Raw       string
	HasCCTV   bool
	Closed    bool
}

var years      = []int{2020, 2021, 2022, 2023, 2024, 2025}
var cctvclosed = []int{2024, 2025}

func main() {
	// Accept both: "--output=csv|json" and bare "csv|json" (for convenience)
	var outputFlag string
	flag.StringVar(&outputFlag, "output", "", "csv|json (default: stdout)")
	flag.Parse()
	if outputFlag == "" && len(flag.Args()) > 0 {
		// Handle when run.sh passes just "csv" or "json"
		switch strings.ToLower(flag.Args()[0]) {
		case "csv", "--output=csv":
			outputFlag = "csv"
		case "json", "--output=json":
			outputFlag = "json"
		}
	} else if strings.HasPrefix(outputFlag, "--output=") {
		outputFlag = strings.TrimPrefix(outputFlag, "--output=")
	}
	outputFlag = strings.ToLower(strings.TrimSpace(outputFlag))

	// ======== FETCH + PARSE ========
	var incidents []Incident
	seen := map[int]bool{}
	for _, y := range append(append([]int{}, years...), cctvclosed...) {
		if seen[y] { continue }
		seen[y] = true
		incidents = append(incidents, fetchYear(y)...)
	}

	// byYear for the senior counts
	byYear := map[int][]Incident{}
	yearSet := map[int]bool{}
	for _, y := range years { yearSet[y] = true }
	for _, it := range incidents {
		if yearSet[it.Year] {
			byYear[it.Year] = append(byYear[it.Year], it)
		}
	}

	type Q1Row struct {
		Year    int
		Seniors int
		Total   int
		Share   float64
	}
	var q1Rows []Q1Row
	for _, y := range years {
		rows := byYear[y]
		seniors := 0
		for _, r := range rows {
			if r.Age != nil && *r.Age >= 60 { seniors++ }
		}
		total := len(rows)
		share := 0.0
		if total > 0 {
			share = float64(seniors) / float64(total) * 100.0
			share = float64(int(share*10+0.5)) / 10.0 // round to 1 dp
		}
		q1Rows = append(q1Rows, Q1Row{Year: y, Seniors: seniors, Total: total, Share: share})
	}

	// CCTV vs closure for 2024–2025
	yrOK := map[int]bool{2024: true, 2025: true}
	a := 0 // with CCTV + closed
	b := 0 // with CCTV + open
	c := 0 // no CCTV + closed
	d := 0 // no CCTV + open
	for _, it := range incidents {
		if !yrOK[it.Year] { continue }
		if it.HasCCTV {
			if it.Closed { a++ } else { b++ }
		} else {
			if it.Closed { c++ } else { d++ }
		}
	}
	camTotal := a + b
	noCamTotal := c + d
	camRate, noCamRate := 0.0, 0.0
	if camTotal > 0 {
		camRate = float64(a) / float64(camTotal) * 100.0
		camRate = float64(int(camRate*10+0.5)) / 10.0
	}
	if noCamTotal > 0 {
		noCamRate = float64(c) / float64(noCamTotal) * 100.0
		noCamRate = float64(int(noCamRate*10+0.5)) / 10.0
	}

	// ======== OUTPUT ========
	switch outputFlag {
	case "":
		fmt.Println("Question 1: How many Baltimore City homicide victims aged 60 or older per year (2020–2025), and what share of that year’s total?\n")
		fmt.Printf("%-6s%-12s%-8s%s\n", "Year", "60+ Count", "Total", "Share 60+")
		for _, r := range q1Rows {
			fmt.Printf("%-6d%-12d%-8d%.1f%%\n", r.Year, r.Seniors, r.Total, r.Share)
		}
		fmt.Println("\nQuestion 2: For 2024–2025, what is the relationship between nearby CCTV (≤1 block) and case closure?\n")
		fmt.Printf("%20s%7s%7s%7s\n", "", "Closed", "Open", "Total")
		fmt.Printf("With CCTV        %6d %7d %7d\n", a, b, camTotal)
		fmt.Printf("No CCTV          %6d %7d %7d\n\n", c, d, noCamTotal)
		fmt.Printf("Closure rate with CCTV:    %.1f%%\n", camRate)
		fmt.Printf("Closure rate without CCTV: %.1f%%\n", noCamRate)

	case "csv":
		_ = os.MkdirAll("/out", 0o755)
		q1 := "year,sixty_plus_count,total,share_pct\n"
		for _, r := range q1Rows {
			q1 += fmt.Sprintf("%d,%d,%d,%.1f\n", r.Year, r.Seniors, r.Total, r.Share)
		}
		if err := os.WriteFile("/out/q1.csv", []byte(q1), 0o644); err != nil { fail(err) }

		q2 := "group,closed,open,total,closure_rate_pct\n" +
			fmt.Sprintf("with_cctv,%d,%d,%d,%.1f\n", a, b, camTotal, camRate) +
			fmt.Sprintf("no_cctv,%d,%d,%d,%.1f\n", c, d, noCamTotal, noCamRate)
		if err := os.WriteFile("/out/q2.csv", []byte(q2), 0o644); err != nil { fail(err) }

		fmt.Println("Wrote /out/q1.csv and /out/q2.csv")

	case "json":
		_ = os.MkdirAll("/out", 0o755)
		type q1Obj struct {
			Year            int     `json:"year"`
			SixtyPlusCount  int     `json:"sixty_plus_count"`
			Total           int     `json:"total"`
			SharePct        float64 `json:"share_pct"`
		}
		q1 := make([]q1Obj, 0, len(q1Rows))
		for _, r := range q1Rows {
			q1 = append(q1, q1Obj{r.Year, r.Seniors, r.Total, r.Share})
		}
		q1Bytes, _ := json.MarshalIndent(q1, "", "  ")
		if err := os.WriteFile("/out/q1.json", q1Bytes, 0o644); err != nil { fail(err) }

		q2 := map[string]any{
			"with_cctv": map[string]any{"closed": a, "open": b, "total": camTotal, "closure_rate_pct": camRate},
			"no_cctv":   map[string]any{"closed": c, "open": d, "total": noCamTotal, "closure_rate_pct": noCamRate},
		}
		q2Bytes, _ := json.MarshalIndent(q2, "", "  ")
		if err := os.WriteFile("/out/q2.json", q2Bytes, 0o644); err != nil { fail(err) }

		fmt.Println("Wrote /out/q1.json and /out/q2.json")

	default:
		fail(errors.New("Unknown output mode. Use --output=csv | --output=json or omit for stdout"))
	}
}

func fail(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(2)
}

// ----------------------- Fetch & Parse -----------------------

func urlFor(year int) string {
	switch year {
	case 2025:
		return "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
	case 2024:
		return "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html"
	case 2023:
		return "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html"
	case 2022:
		return "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html"
	case 2021:
		return "https://chamspage.blogspot.com/2021/01/2021-baltimore-city-homicides-list.html"
	case 2020:
		return "https://chamspage.blogspot.com/2020/01/2020-baltimore-city-homicides-list.html"
	default:
		return fmt.Sprintf("https://chamspage.blogspot.com/%d/", year)
	}
}

func fetchYear(year int) []Incident {
	url := urlFor(year)
	body, err := httpGet(url)
	if err != nil {
		fmt.Fprintf(os.Stderr, "[WARN] Failed to fetch %d: %v\n", year, err)
		return nil
	}
	// collapse whitespace and strip tags quick-and-dirty
	txt := collapseSpaces(stripTags(body))

	// Pattern similar to your Scala version, without lookbehind (Go's RE2)
	re := regexp.MustCompile(`(\d{3})\s(\d{2}/\d{2}/\d{2})\s([^\d][^\s].*?)\s(\d{1,3})\s(.*?)(?=\s\d{3}\s\d{2}/\d{2}/\d{2}\s|$)`)
	matches := re.FindAllStringSubmatch(txt, -1)

	var out []Incident
	for _, m := range matches {
		number := atoi(m[1])
		dateStr := m[2]
		name := strings.TrimSpace(m[3])
		age := atoiPtrOrNil(m[4])
		raw := strings.TrimSpace(m[5])

		hasCCTV := reAny(raw, `(?i)\b\d+\s*camera`) || reAny(raw, `(?i)surveillance camera`)
		closed  := reAny(raw, `(?i)\bclosed\b`)

		address := firstNonEmpty(splitMultiSpace(raw), raw)
		out = append(out, Incident{
			Year: year, Number: number, Address: address, DateStr: dateStr,
			Name: name, Age: age, Raw: raw, HasCCTV: hasCCTV, Closed: closed,
		})
	}
	return out
}

func httpGet(url string) (string, error) {
	client := &http.Client{ Timeout: 30 * time.Second }
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome Safari")
	req.Header.Set("Referer", "https://www.google.com/")
	resp, err := client.Do(req)
	if err != nil { return "", err }
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("HTTP %d", resp.StatusCode)
	}
	b, err := io.ReadAll(resp.Body)
	if err != nil { return "", err }
	return string(b), nil
}

func stripTags(s string) string {
	// crude but effective for our purpose
	re := regexp.MustCompile(`(?s)<[^>]+>`)
	return re.ReplaceAllString(s, " ")
}

func collapseSpaces(s string) string {
	s = strings.ReplaceAll(s, "\u00a0", " ")
	re := regexp.MustCompile(`\s+`)
	return re.ReplaceAllString(strings.TrimSpace(s), " ")
}

func splitMultiSpace(s string) []string {
	re := regexp.MustCompile(`\s{2,}`)
	return re.Split(s, -1)
}

func firstNonEmpty(parts []string, fallback string) string {
	for _, p := range parts {
		if strings.TrimSpace(p) != "" { return strings.TrimSpace(p) }
	}
	return fallback
}

func reAny(s, pattern string) bool {
	re := regexp.MustCompile(pattern)
	return re.FindStringIndex(s) != nil
}

func atoi(s string) int {
	n := 0
	for _, r := range s {
		if r < '0' || r > '9' { return n }
		n = n*10 + int(r-'0')
	}
	return n
}

func atoiPtrOrNil(s string) *int {
	if s == "" { return nil }
	n := atoi(s)
	if n == 0 && s != "0" { return nil }
	return &n
}
