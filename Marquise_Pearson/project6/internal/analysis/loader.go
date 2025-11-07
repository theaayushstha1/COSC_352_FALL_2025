package analysis

import (
	"bufio"
	"encoding/csv"
	"errors"
	"io"
	"os"
	"strconv"
	"strings"
)

// ---------- Aggregated rows (matches results.csv) ----------

type AggRow struct {
	City        string
	Count       int
	RecordType  string
	Year        int
	DiffFromAvg float64
	Offense     string
	PercentDiff float64
	Month       int
	Total       int
}
type AggRows []AggRow

type Loaded struct {
	Agg AggRows
}

// Loader expects aggregated CSV with at least: count, year, month
func Load(path string) (Loaded, error) {
	f, err := os.Open(path)
	if err != nil {
		return Loaded{}, err
	}
	defer f.Close()

	r := csv.NewReader(bufio.NewReader(f))
	r.FieldsPerRecord = -1

	// header
	head, err := r.Read()
	if err != nil {
		return Loaded{}, err
	}
	idx := map[string]int{}
	for i, h := range head {
		idx[strings.ToLower(strings.TrimSpace(h))] = i
	}

	// minimal schema check
	if _, ok := idx["count"]; !ok {
		return Loaded{}, errors.New("input must include columns: count, year, month")
	}
	if _, ok := idx["year"]; !ok {
		return Loaded{}, errors.New("input must include columns: count, year, month")
	}
	if _, ok := idx["month"]; !ok {
		return Loaded{}, errors.New("input must include columns: count, year, month")
	}

	var rows AggRows
	for {
		row, err := r.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			return Loaded{}, err
		}
		rows = append(rows, AggRow{
			City:        fieldOpt(row, idx, "city"),
			Count:       atoi(fieldOpt(row, idx, "count")),
			RecordType:  fieldOpt(row, idx, "record_type"),
			Year:        atoi(fieldOpt(row, idx, "year")),
			DiffFromAvg: atof(fieldOpt(row, idx, "diff_from_avg")),
			Offense:     fieldOpt(row, idx, "offense"),
			PercentDiff: atof(firstNonEmpty(
				fieldOpt(row, idx, "percent_diff_avg_to_date"),
				fieldOpt(row, idx, "percent_diff"),
			)),
			Month: atoi(fieldOpt(row, idx, "month")),
			Total: atoi(firstNonEmpty(
				fieldOpt(row, idx, "total"),
				fieldOpt(row, idx, "total_known"),
			)),
		})
	}

	return Loaded{Agg: rows}, nil
}

// ---------- helpers ----------

func field(row []string, i int) string {
	if i < 0 || i >= len(row) {
		return ""
	}
	return strings.TrimSpace(row[i])
}

func fieldOpt(row []string, idx map[string]int, key string) string {
	i, exists := idx[key]
	if !exists {
		return ""
	}
	return field(row, i)
}

func firstNonEmpty(vals ...string) string {
	for _, v := range vals {
		if strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}

func atoi(s string) int {
	// strip % and commas if present
	s = strings.ReplaceAll(strings.ReplaceAll(strings.TrimSpace(s), ",", ""), "%", "")
	n, _ := strconv.Atoi(s)
	return n
}

func atof(s string) float64 {
	// strip % and commas if present
	s = strings.ReplaceAll(strings.ReplaceAll(strings.TrimSpace(s), ",", ""), "%", "")
	f, _ := strconv.ParseFloat(s, 64)
	return f
}
