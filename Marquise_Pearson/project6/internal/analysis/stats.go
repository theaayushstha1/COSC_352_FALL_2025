package analysis

import "sort"

// Q1 — monthly totals (sum Count per Month for the given Year)
func MonthlyTotals(rows AggRows, year int) map[int]int {
	out := make(map[int]int)
	for _, r := range rows {
		if r.Year == year {
			out[r.Month] += r.Count
		}
	}
	return out
}

// Q2 — totals by RecordType (fallback to Offense if empty)
func RecordTypeTotals(rows AggRows, year int) map[string]int {
	out := make(map[string]int)
	for _, r := range rows {
		if r.Year == year {
			key := r.RecordType
			if key == "" {
				key = r.Offense
			}
			if key == "" {
				key = "(unknown)"
			}
			out[key] += r.Count
		}
	}
	return out
}

// Q3 — monthly diff-from-average (last seen value for month)
func MonthlyDiffFromAvg(rows AggRows, year int) map[int]float64 {
	out := make(map[int]float64)
	for _, r := range rows {
		if r.Year == year {
			out[r.Month] = r.DiffFromAvg
		}
	}
	return out
}

// ---- small sort helpers (used by writer) ----
func SortedIntKeys(m map[int]int) []int {
	keys := make([]int, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Ints(keys)
	return keys
}

func SortedFloatKeys(m map[int]float64) []int {
	keys := make([]int, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Ints(keys)
	return keys
}

func SortedStringKeys(m map[string]int) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}
