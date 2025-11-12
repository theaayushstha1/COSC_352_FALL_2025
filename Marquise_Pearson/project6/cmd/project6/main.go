package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"project6/internal/analysis"
)

func main() {
	var (
		input  string
		year   int
		q      string
		outFmt string
	)

	flag.StringVar(&input, "input", "", "Path to input CSV (required)")
	flag.IntVar(&year, "year", 0, "Filter by year (required)")
	flag.StringVar(&q, "question", "q1", "q1|q2|q3 (q1=monthly totals, q2=type totals, q3=monthly diff-from-avg)")
	flag.StringVar(&outFmt, "out", "text", "Output: text|json|csv")
	flag.Parse()

	if input == "" || year == 0 {
		log.Fatalf("usage: %s --input PATH --year YYYY --question q1|q2|q3 --out text|json|csv", os.Args[0])
	}

	loaded, err := analysis.Load(input)
	if err != nil {
		log.Fatal(err)
	}

	switch q {
	case "q1":
		m := analysis.MonthlyTotals(loaded.Agg, year)
		if err := analysis.WriteMonthlyCounts(m, outFmt, os.Stdout); err != nil {
			log.Fatal(err)
		}
	case "q2":
		m := analysis.RecordTypeTotals(loaded.Agg, year)
		if err := analysis.WriteRecordTypeCounts(m, outFmt, os.Stdout); err != nil {
			log.Fatal(err)
		}
	case "q3":
		m := analysis.MonthlyDiffFromAvg(loaded.Agg, year)
		if err := analysis.WriteMonthlyDiffs(m, outFmt, os.Stdout); err != nil {
			log.Fatal(err)
		}
	default:
		log.Fatalf("unknown --question %q; use q1|q2|q3", q)
	}

	fmt.Fprintln(os.Stderr, "(done)")
}
