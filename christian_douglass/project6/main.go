package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"

	"github.com/PuerkitoBio/goquery"
)

const url = "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"

// Homicide represents one row of the table.
type Homicide struct {
	No             string  `json:"no"`
	Date           string  `json:"date"`
	Name           string  `json:"name"`
	Age            *int    `json:"age"`
	Address        string  `json:"address"`
	Notes          string  `json:"notes"`
	CriminalHistory string `json:"criminalHistory"`
	Camera         string  `json:"camera"`
	CaseClosed     string  `json:"caseClosed"`
}

func parseAge(s string) *int {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil
	}
	if v, err := strconv.Atoi(s); err == nil {
		return &v
	}
	return nil
}

func fetchAndParse() ([]Homicide, error) {
	client := &http.Client{}
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", "Mozilla/5.0")
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	doc, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		return nil, err
	}

	var entries []Homicide
	doc.Find("#homicidelist tbody tr").Each(func(i int, s *goquery.Selection) {
		var tds []string
		s.Find("td").Each(func(i int, td *goquery.Selection) {
			text := strings.TrimSpace(td.Text())
			tds = append(tds, text)
		})
		if len(tds) == 0 {
			return
		}
		// skip header-like rows
		skip := false
		for _, v := range tds {
			lv := strings.ToLower(v)
			if strings.Contains(lv, "no.") || strings.Contains(lv, "date died") {
				skip = true
				break
			}
		}
		if skip { return }

		get := func(i int) string {
			if i < len(tds) { return tds[i] }
			return ""
		}
		age := parseAge(get(3))
		e := Homicide{
			No: get(0),
			Date: get(1),
			Name: get(2),
			Age: age,
			Address: get(4),
			Notes: get(5),
			CriminalHistory: get(6),
			Camera: get(7),
			CaseClosed: get(8),
		}
		entries = append(entries, e)
	})

	return entries, nil
}

func writeCSV(entries []Homicide, w io.Writer) error {
	cw := csv.NewWriter(w)
	defer cw.Flush()
	header := []string{"no","date","name","age","address","notes","criminalHistory","camera","caseClosed"}
	if err := cw.Write(header); err != nil { return err }
	for _, e := range entries {
		ageStr := ""
		if e.Age != nil { ageStr = strconv.Itoa(*e.Age) }
		rec := []string{e.No, e.Date, e.Name, ageStr, e.Address, e.Notes, e.CriminalHistory, e.Camera, e.CaseClosed}
		if err := cw.Write(rec); err != nil { return err }
	}
	return nil
}

func writeJSON(entries []Homicide, w io.Writer) error {
	enc := json.NewEncoder(w)
	enc.SetEscapeHTML(false)
	enc.SetIndent("", "  ")
	return enc.Encode(entries)
}

func closedRate(list []Homicide) (closed int, total int, pct float64) {
	total = len(list)
	for _, e := range list {
		if strings.EqualFold(e.CaseClosed, "Closed") || strings.Contains(strings.ToLower(e.CaseClosed), "closed") {
			closed++
		}
	}
	if total == 0 { pct = 0.0 } else { pct = (float64(closed) / float64(total)) * 100.0 }
	return
}

func textualAnalysis(entries []Homicide, out io.Writer) {
	fmt.Fprintln(out, "Question 1: Top homicide hotspots (address block) in 2025")
	byAddr := map[string]int{}
	for _, e := range entries {
		if strings.TrimSpace(e.Address) != "" {
			byAddr[e.Address]++
		}
	}
	type kv struct { k string; v int }
	var kvs []kv
	for k, v := range byAddr { kvs = append(kvs, kv{k, v}) }
	sort.Slice(kvs, func(i, j int) bool { return kvs[i].v > kvs[j].v })
	if len(kvs) == 0 { fmt.Fprintln(out, "No data found for hotspots.") } else {
		fmt.Fprintln(out, "Address Block | Count")
		top := 10
		if len(kvs) < top { top = len(kvs) }
		for i := 0; i < top; i++ { fmt.Fprintf(out, "%s | %d\n", kvs[i].k, kvs[i].v) }
		fmt.Fprintln(out)
		for i := 0; i < top; i++ {
			addr := kvs[i].k
			fmt.Fprintf(out, "Victims at %s:\n", addr)
			count := 0
			for _, e := range entries {
				if e.Address == addr {
					ageStr := ""
					if e.Age != nil { ageStr = strconv.Itoa(*e.Age) }
					fmt.Fprintf(out, "%s | %s | %s | %s\n", e.No, e.Date, e.Name, ageStr)
					count++
					if count >= 5 { break }
				}
			}
			fmt.Fprintln(out)
		}
	}

	fmt.Fprintln(out, "Question 2: Do homicides with surveillance cameras have higher closure rates?")
	var withCamera, withoutCamera []Homicide
	for _, e := range entries {
		if strings.TrimSpace(e.Camera) != "" { withCamera = append(withCamera, e) } else { withoutCamera = append(withoutCamera, e) }
	}
	c1, t1, p1 := closedRate(withCamera)
	c2, t2, p2 := closedRate(withoutCamera)
	fmt.Fprintf(out, "With camera: %d/%d closed (%.1f%%)\n", c1, t1, p1)
	fmt.Fprintf(out, "Without camera: %d/%d closed (%.1f%%)\n", c2, t2, p2)
	fmt.Fprintln(out)
	fmt.Fprintln(out, "Examples of camera cases that remain open (if any):")
	count := 0
	for _, e := range withCamera {
		if !(strings.EqualFold(e.CaseClosed, "Closed") || strings.Contains(strings.ToLower(e.CaseClosed), "closed")) {
			fmt.Fprintf(out, "%s | %s | %s | %s | camera:%s | caseClosed:'%s'\n", e.No, e.Date, e.Name, e.Address, e.Camera, e.CaseClosed)
			count++
			if count >= 10 { break }
		}
	}
}

func main() {
	outputMode := flag.String("output", "stdout", "output mode: csv, json, or stdout (analysis)")
	outFile := flag.String("out-file", "", "optional output file path (use '-' for stdout)")
	flag.Parse()

	entries, err := fetchAndParse()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error fetching/parsing: %v\n", err)
		os.Exit(1)
	}

	mode := strings.ToLower(strings.TrimSpace(*outputMode))
	if mode == "csv" || mode == "json" {
		var w io.Writer
		if *outFile == "-" {
			w = os.Stdout
		} else if *outFile != "" {
			f, err := os.Create(*outFile)
			if err != nil { fmt.Fprintf(os.Stderr, "Error creating file: %v\n", err); os.Exit(1) }
			defer f.Close()
			w = f
		} else {
			// default file names
			name := ""
			if mode == "csv" { name = "homicides_2025.csv" } else { name = "homicides_2025.json" }
			f, err := os.Create(name)
			if err != nil { fmt.Fprintf(os.Stderr, "Error creating file: %v\n", err); os.Exit(1) }
			defer f.Close()
			w = f
		}
		if mode == "csv" {
			if err := writeCSV(entries, w); err != nil { fmt.Fprintf(os.Stderr, "CSV write error: %v\n", err); os.Exit(1) }
			fmt.Fprintf(os.Stdout, "Wrote %d records\n", len(entries))
			return
		}
		if mode == "json" {
			if err := writeJSON(entries, w); err != nil { fmt.Fprintf(os.Stderr, "JSON write error: %v\n", err); os.Exit(1) }
			fmt.Fprintf(os.Stdout, "Wrote %d records\n", len(entries))
			return
		}
	}

	// default: textual analysis to stdout
	textualAnalysis(entries, os.Stdout)
}
