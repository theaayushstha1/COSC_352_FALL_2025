package analysis

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io"
)

// WriteMonthlyCounts renders map[month]int in the chosen format.
func WriteMonthlyCounts(m map[int]int, outFmt string, w io.Writer) error {
	switch outFmt {
	case "text":
		fmt.Fprintln(w, "Month | Count")
		for _, month := range SortedIntKeys(m) {
			fmt.Fprintf(w, "%5d | %d\n", month, m[month])
		}
	case "json":
		type row struct{ Month, Count int }
		var rows []row
		for _, month := range SortedIntKeys(m) {
			rows = append(rows, row{Month: month, Count: m[month]})
		}
		enc := json.NewEncoder(w)
		enc.SetIndent("", "  ")
		return enc.Encode(rows)
	case "csv":
		cw := csv.NewWriter(w); defer cw.Flush()
		_ = cw.Write([]string{"month", "count"})
		for _, month := range SortedIntKeys(m) {
			_ = cw.Write([]string{fmt.Sprint(month), fmt.Sprint(m[month])})
		}
	default:
		return fmt.Errorf("unknown --out %q", outFmt)
	}
	return nil
}

// WriteRecordTypeCounts renders map[type]int
func WriteRecordTypeCounts(m map[string]int, outFmt string, w io.Writer) error {
	switch outFmt {
	case "text":
		fmt.Fprintln(w, "Type | Count")
		for _, k := range SortedStringKeys(m) {
			fmt.Fprintf(w, "%s | %d\n", k, m[k])
		}
	case "json":
		type row struct{ Type string; Count int }
		var rows []row
		for _, k := range SortedStringKeys(m) {
			rows = append(rows, row{Type: k, Count: m[k]})
		}
		enc := json.NewEncoder(w)
		enc.SetIndent("", "  ")
		return enc.Encode(rows)
	case "csv":
		cw := csv.NewWriter(w); defer cw.Flush()
		_ = cw.Write([]string{"type", "count"})
		for _, k := range SortedStringKeys(m) {
			_ = cw.Write([]string{k, fmt.Sprint(m[k])})
		}
	default:
		return fmt.Errorf("unknown --out %q", outFmt)
	}
	return nil
}

// WriteMonthlyDiffs renders map[month]float64
func WriteMonthlyDiffs(m map[int]float64, outFmt string, w io.Writer) error {
	switch outFmt {
	case "text":
		fmt.Fprintln(w, "Month | DiffFromAvg")
		for _, month := range SortedFloatKeys(m) {
			fmt.Fprintf(w, "%5d | %.2f\n", month, m[month])
		}
	case "json":
		type row struct{ Month int; DiffFromAvg float64 }
		var rows []row
		for _, month := range SortedFloatKeys(m) {
			rows = append(rows, row{Month: month, DiffFromAvg: m[month]})
		}
		enc := json.NewEncoder(w)
		enc.SetIndent("", "  ")
		return enc.Encode(rows)
	case "csv":
		cw := csv.NewWriter(w); defer cw.Flush()
		_ = cw.Write([]string{"month", "diff_from_avg"})
		for _, month := range SortedFloatKeys(m) {
			_ = cw.Write([]string{fmt.Sprint(month), fmt.Sprintf("%.2f", m[month])})
		}
	default:
		return fmt.Errorf("unknown --out %q", outFmt)
	}
	return nil
}
