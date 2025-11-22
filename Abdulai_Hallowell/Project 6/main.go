package main

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

type QA struct {
	Question string `json:"question"`
	Answer   string `json:"answer"`
}
type Result struct {
	Results []QA `json:"results"`
}

func toInt(s string) (int, bool) {
	i, err := strconv.Atoi(strings.TrimSpace(s))
	return i, err == nil
}

func main() {
	// OUTPUT: stdout | csv | json
	output := strings.ToLower(strings.TrimSpace(os.Getenv("OUTPUT")))
	if output == "" {
		output = "stdout"
	}

	f, err := os.Open("data.csv")
	if err != nil {
		panic(err)
	}
	defer f.Close()

	r := csv.NewReader(f)
	rows, err := r.ReadAll()
	if err != nil {
		panic(err)
	}
	if len(rows) <= 1 {
		fmt.Println("No data rows found.")
		return
	}
	data := rows[1:] // skip header

	// Column assumptions: age at index 3, circumstance at index 5
	const ageIdx = 3
	const circumstanceIdx = 5

	// Q1: killed at/near home
	nearHome := 0
	for _, row := range data {
		if len(row) > circumstanceIdx {
			c := strings.ToLower(row[circumstanceIdx])
			if strings.Contains(c, "home") || strings.Contains(c, "residence") {
				nearHome++
			}
		}
	}
	q1 := "Question 1: How many homicide victims in 2025 were killed at or near their home?"
	a1 := fmt.Sprintf("Answer: %d cases", nearHome)

	// Q2: % under 25
	total := 0
	youth := 0
	for _, row := range data {
		if len(row) > ageIdx {
			if age, ok := toInt(row[ageIdx]); ok {
				total++
				if age < 25 {
					youth++
				}
			}
		}
	}
	pct := 0.0
	if total > 0 {
		pct = (float64(youth) / float64(total)) * 100.0
	}
	q2 := "Question 2: What percentage of 2025 homicide victims were under 25 years old?"
	a2 := fmt.Sprintf("Answer: %.2f%%", pct)

	switch output {
	case "csv":
		out := filepath.Join("/app", "output.csv")
		w, err := os.Create(out)
		if err != nil {
			panic(err)
		}
		defer w.Close()
		_, _ = w.WriteString("Question,Answer\n")
		_, _ = w.WriteString(fmt.Sprintf("\"%s\",\"%s\"\n", q1, a1))
		_, _ = w.WriteString(fmt.Sprintf("\"%s\",\"%s\"\n", q2, a2))
		fmt.Println("✅ Results written to output.csv")
	case "json":
		out := filepath.Join("/app", "output.json")
		w, err := os.Create(out)
		if err != nil {
			panic(err)
		}
		defer w.Close()
		res := Result{Results: []QA{
			{Question: q1, Answer: a1},
			{Question: q2, Answer: a2},
		}}
		enc := json.NewEncoder(w)
		enc.SetIndent("", "  ")
		if err := enc.Encode(res); err != nil {
			panic(err)
		}
		fmt.Println("✅ Results written to output.json")
	default:
		fmt.Printf("%s\n%s\n\n%s\n%s\n", q1, a1, q2, a2)
	}
}
