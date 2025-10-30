package main

import (
	"encoding/csv"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
)

type Record struct {
	Year int
	Age  *int
}

var (
	years      = []int{2020, 2021, 2022, 2023, 2024, 2025}
	rowRe      = regexp.MustCompile(`(?s)<tr[^>]*>(.*?)</tr>`)
	cellRe     = regexp.MustCompile(`(?s)<t[dh][^>]*>(.*?)</t[dh]>`)
	tagRe      = regexp.MustCompile(`(?s)<[^>]+>`)
	numRe      = regexp.MustCompile(`\d+`)   // ✅ fixed: single backslash, matches digits correctly
	httpClient = &http.Client{Timeout: 20 * time.Second}
)

type pair struct {
	year  int
	count int
}

func main() {
	out, err := parseCLI()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(2)
	}

	var all []Record
	for _, y := range years {
		all = append(all, fetchYear(y)...)
	}

	byYear := map[int][]Record{}
	for _, r := range all {
		byYear[r.Year] = append(byYear[r.Year], r)
	}
	sort.Ints(years)

	q1, q2 := []pair{}, []pair{}
	for _, y := range years {
		recs := byYear[y]
		u18 := 0
		for _, r := range recs {
			if r.Age != nil && *r.Age <= 18 {
				u18++
			}
		}
		q1 = append(q1, pair{y, u18})
		q2 = append(q2, pair{y, len(recs)})
	}

	switch out {
	case "":
		printStdout(toStruct(q1), toStruct(q2))
	case "csv":
		if err := writeCSV(toStruct(q1), toStruct(q2), "/app/out/output.csv"); err != nil {
			fmt.Fprintln(os.Stderr, "Error writing CSV:", err)
			os.Exit(1)
		}
		fmt.Println("✅ Data written to out/output.csv")
	case "json":
		if err := writeJSON(toStruct(q1), toStruct(q2), "/app/out/output.json"); err != nil {
			fmt.Fprintln(os.Stderr, "Error writing JSON:", err)
			os.Exit(1)
		}
		fmt.Println("✅ Data written to out/output.json")
	}
}

func parseCLI() (string, error) {
	var out string
	flag.StringVar(&out, "output", "", "output format: csv | json (default stdout)")
	flag.Parse()
	out = strings.ToLower(strings.TrimSpace(out))
	if out != "" && out != "csv" && out != "json" {
		return "", errors.New("--output must be empty, 'csv', or 'json'")
	}
	return out, nil
}

func printStdout(q1, q2 []struct{ year, count int }) {
	fmt.Println("Question 1: Victims age 18 or younger per year (2020–2025)\n")
	fmt.Println("Year | ≤18 Victims")
	fmt.Println("------------------")
	for _, p := range q1 {
		fmt.Printf("%-5d| %4d\n", p.year, p.count)
	}

	fmt.Println("\n--------------------------------------------------\n")

	fmt.Println("Question 2: Total homicide victims per year (2020–2025)\n")
	fmt.Println("Year | Total Victims")
	fmt.Println("--------------------")
	for _, p := range q2 {
		fmt.Printf("%-5d| %4d\n", p.year, p.count)
	}
}

func writeCSV(q1, q2 []struct{ year, count int }, path string) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	w := csv.NewWriter(f)
	defer w.Flush()

	w.Write([]string{"year", "under18", "total"})
	for _, p := range q1 {
		t := findCount(q2, p.year)
		w.Write([]string{fmt.Sprint(p.year), fmt.Sprint(p.count), fmt.Sprint(t)})
	}
	return nil
}

func writeJSON(q1, q2 []struct{ year, count int }, path string) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	type item struct {
		Year    int `json:"year"`
		Under18 int `json:"under18"`
		Total   int `json:"total"`
	}
	items := make([]item, 0, len(q1))
	for _, p := range q1 {
		items = append(items, item{p.year, p.count, findCount(q2, p.year)})
	}
	enc := json.NewEncoder(f)
	enc.SetIndent("", "  ")
	return enc.Encode(items)
}

func findCount(pairs []struct{ year, count int }, y int) int {
	for _, p := range pairs {
		if p.year == y {
			return p.count
		}
	}
	return 0
}

func toStruct(pairs []pair) []struct{ year, count int } {
	out := make([]struct{ year, count int }, len(pairs))
	for i, p := range pairs {
		out[i] = struct{ year, count int }{p.year, p.count}
	}
	return out
}

func fetchYear(year int) []Record {
	urls := []string{
		fmt.Sprintf("https://chamspage.blogspot.com/%d/01/%d-baltimore-city-homicides-list.html", year, year),
		fmt.Sprintf("https://chamspage.blogspot.com/%d/01/%d-baltimore-city-homicide-list.html", year, year),
		fmt.Sprintf("https://chamspage.blogspot.com/%d/01/%d-baltimore-city-homicides-list-and-map.html", year, year),
	}
	var html string
	for _, u := range urls {
		if h, ok := fetch(u); ok {
			html = h
			break
		}
	}
	if html == "" {
		return nil
	}
	return parseYear(html, year)
}


func parseYear(html string, year int) []Record {
	rows := rowRe.FindAllStringSubmatch(html, -1)
	if len(rows) == 0 {
		return nil
	}
	var recs []Record
	for i, m := range rows {
		if i == 0 {
			continue
		}
		cells := cellRe.FindAllStringSubmatch(m[1], -1)
		if len(cells) < 4 {
			continue
		}
		clean := func(s string) string {
			s = tagRe.ReplaceAllString(s, " ")
			s = strings.ReplaceAll(s, "&nbsp;", " ")
			s = strings.ReplaceAll(s, "&amp;", "&")
			return strings.Join(strings.Fields(s), " ")
		}
		ageText := clean(cells[3][1])
		var agePtr *int
		if n := numRe.FindString(ageText); n != "" {
			if v, err := atoiSafe(n); err == nil {
				agePtr = &v
			}
		}
		recs = append(recs, Record{Year: year, Age: agePtr})
	}
	return recs
}

func atoiSafe(s string) (int, error) {
	n := 0
	for _, r := range s {
		if r < '0' || r > '9' {
			return 0, fmt.Errorf("invalid digit")
		}
		n = n*10 + int(r-'0')
	}
	return n, nil
}

// --- patched fetch() that mimics desktop browser ---

// --- debug fetch() that shows first 500 bytes of the HTML ---
func fetch(url string) (string, bool) {
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return "", false
	}
	req.Header.Set("User-Agent",
		"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36")
	req.Header.Set("Accept-Language", "en-US,en;q=0.9")

	client := &http.Client{
		Timeout: 30 * time.Second,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return nil // follow redirects
		},
	}

	resp, err := client.Do(req)
	if err != nil {
		fmt.Println("❌ request error:", err)
		return "", false
	}
	defer resp.Body.Close()

	if resp.StatusCode/100 != 2 {
		fmt.Println("❌", resp.Status, "for", url)
		return "", false
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("❌ read error:", err)
		return "", false
	}

	fmt.Println("✅ fetched", url, "bytes:", len(body))
	if len(body) > 500 {
		fmt.Println("---- HTML PREVIEW ----")
		fmt.Println(string(body[:500]))
		fmt.Println("---- END PREVIEW ----")
	} else {
		fmt.Println("---- HTML PREVIEW ----")
		fmt.Println(string(body))
		fmt.Println("---- END PREVIEW ----")
	}

	time.Sleep(2 * time.Second) // polite delay
	return string(body), true
}
