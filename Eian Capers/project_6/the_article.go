package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"sort"
	"strconv"
	"strings"
)

// HomicideRecord represents a single homicide case
type HomicideRecord struct {
	No                  string
	DateDied            string
	Name                string
	Age                 string
	Address             string
	Notes               string
	NoViolentHistory    string
	SurveillanceCamera  string
	CaseClosed          string
}

// CameraStats holds statistics about cases with/without cameras
type CameraStats struct {
	WithTotal      int
	WithClosed     int
	WithRate       float64
	WithoutTotal   int
	WithoutClosed  int
	WithoutRate    float64
	Diff           float64
}

// MonthStats holds statistics for a specific month
type MonthStats struct {
	MonthNum  int
	MonthName string
	Count     int
	AvgAge    *float64
}

// JSONOutput structures for JSON export
type JSONCameraAnalysis struct {
	WithCamera struct {
		TotalCases  int     `json:"totalCases"`
		CasesClosed int     `json:"casesClosed"`
		ClosureRate float64 `json:"closureRate"`
	} `json:"withCamera"`
	WithoutCamera struct {
		TotalCases  int     `json:"totalCases"`
		CasesClosed int     `json:"casesClosed"`
		ClosureRate float64 `json:"closureRate"`
	} `json:"withoutCamera"`
	ClosureRateDifference float64 `json:"closureRateDifference"`
}

type JSONMonthly struct {
	Month            int      `json:"month"`
	MonthName        string   `json:"monthName"`
	HomicideCount    int      `json:"homicideCount"`
	AverageVictimAge *float64 `json:"averageVictimAge"`
}

type JSONSummary struct {
	MostDangerousMonth struct {
		Month     string `json:"month"`
		Homicides int    `json:"homicides"`
	} `json:"mostDangerousMonth"`
	SafestMonth struct {
		Month     string `json:"month"`
		Homicides int    `json:"homicides"`
	} `json:"safestMonth"`
	OverallAverageVictimAge *float64 `json:"overallAverageVictimAge"`
}

type JSONOutput struct {
	Analysis          string             `json:"analysis"`
	DataSource        string             `json:"dataSource"`
	TotalRecords      int                `json:"totalRecords"`
	CameraAnalysis    JSONCameraAnalysis `json:"cameraAnalysis"`
	MonthlyStatistics []JSONMonthly      `json:"monthlyStatistics"`
	Summary           JSONSummary        `json:"summary"`
}

var monthNames = []string{"", "January", "February", "March", "April",
	"May", "June", "July", "August", "September", "October",
	"November", "December"}

func main() {
	outputFormat := flag.String("output", "stdout", "Output format: stdout, csv, or json")
	flag.Parse()

	csvFile := "info_death.csv"
	records, err := parseCSV(csvFile)
	if err != nil || len(records) == 0 {
		fmt.Println("ERROR: Could not load data from CSV file")
		os.Exit(1)
	}

	cameraStats := computeCameraStats(records)
	monthlyStats := computeMonthlyStats(records)

	switch *outputFormat {
	case "csv":
		outputCSV(records, cameraStats, monthlyStats)
	case "json":
		outputJSON(records, cameraStats, monthlyStats)
	default:
		outputStdout(records, cameraStats, monthlyStats)
	}
}

func parseCSV(filename string) ([]HomicideRecord, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	reader := csv.NewReader(file)
	lines, err := reader.ReadAll()
	if err != nil {
		return nil, err
	}

	var records []HomicideRecord
	for i, line := range lines {
		// Skip header
		if i == 0 {
			continue
		}

		if len(line) >= 9 && line[0] != "" {
			records = append(records, HomicideRecord{
				No:                 line[0],
				DateDied:           line[1],
				Name:               line[2],
				Age:                line[3],
				Address:            line[4],
				Notes:              line[5],
				NoViolentHistory:   line[6],
				SurveillanceCamera: line[7],
				CaseClosed:         line[8],
			})
		}
	}

	return records, nil
}

func parseMonth(dateStr string) (int, bool) {
	parts := strings.Split(dateStr, "/")
	if len(parts) >= 1 && parts[0] != "" {
		month, err := strconv.Atoi(parts[0])
		if err == nil && month >= 1 && month <= 12 {
			return month, true
		}
	}
	return 0, false
}

func parseAge(ageStr string) (int, bool) {
	age, err := strconv.Atoi(ageStr)
	if err == nil && age > 0 {
		return age, true
	}
	return 0, false
}

func computeCameraStats(records []HomicideRecord) CameraStats {
	var withCameras, withoutCameras []HomicideRecord

	for _, r := range records {
		if r.SurveillanceCamera != "" && 
		   strings.Contains(strings.ToLower(r.SurveillanceCamera), "camera") {
			withCameras = append(withCameras, r)
		} else {
			withoutCameras = append(withoutCameras, r)
		}
	}

	withCamerasClosed := 0
	for _, r := range withCameras {
		if strings.ToLower(r.CaseClosed) == "closed" {
			withCamerasClosed++
		}
	}

	withoutCamerasClosed := 0
	for _, r := range withoutCameras {
		if strings.ToLower(r.CaseClosed) == "closed" {
			withoutCamerasClosed++
		}
	}

	withRate := 0.0
	if len(withCameras) > 0 {
		withRate = float64(withCamerasClosed) / float64(len(withCameras)) * 100
	}

	withoutRate := 0.0
	if len(withoutCameras) > 0 {
		withoutRate = float64(withoutCamerasClosed) / float64(len(withoutCameras)) * 100
	}

	return CameraStats{
		WithTotal:     len(withCameras),
		WithClosed:    withCamerasClosed,
		WithRate:      withRate,
		WithoutTotal:  len(withoutCameras),
		WithoutClosed: withoutCamerasClosed,
		WithoutRate:   withoutRate,
		Diff:          withRate - withoutRate,
	}
}

func computeMonthlyStats(records []HomicideRecord) []MonthStats {
	byMonth := make(map[int][]HomicideRecord)

	for _, r := range records {
		if month, ok := parseMonth(r.DateDied); ok {
			byMonth[month] = append(byMonth[month], r)
		}
	}

	var stats []MonthStats
	for m := 1; m <= 12; m++ {
		recs := byMonth[m]
		var ages []int
		for _, r := range recs {
			if age, ok := parseAge(r.Age); ok {
				ages = append(ages, age)
			}
		}

		var avgAge *float64
		if len(ages) > 0 {
			sum := 0
			for _, age := range ages {
				sum += age
			}
			avg := float64(sum) / float64(len(ages))
			avgAge = &avg
		}

		stats = append(stats, MonthStats{
			MonthNum:  m,
			MonthName: monthNames[m],
			Count:     len(recs),
			AvgAge:    avgAge,
		})
	}

	// Sort by count (descending)
	sort.Slice(stats, func(i, j int) bool {
		return stats[i].Count > stats[j].Count
	})

	return stats
}

func outputStdout(records []HomicideRecord, cameraStats CameraStats, monthlyStats []MonthStats) {
	fmt.Println(strings.Repeat("=", 70))
	fmt.Println("BALTIMORE HOMICIDE DATA ANALYSIS")
	fmt.Println("Data Source: chamspage.blogspot.com")
	fmt.Println(strings.Repeat("=", 70))
	fmt.Printf("\n✓ Successfully loaded %d homicide records\n\n", len(records))

	fmt.Println(strings.Repeat("=", 70))
	fmt.Println("QUESTION 1: What percentage of homicide cases with surveillance")
	fmt.Println("            cameras get closed compared to cases without cameras?")
	fmt.Println(strings.Repeat("=", 70))

	fmt.Printf("\nCases WITH surveillance cameras: %d\n", cameraStats.WithTotal)
	fmt.Printf("  - Closed: %d\n", cameraStats.WithClosed)
	fmt.Printf("  - Closure rate: %.2f%%\n", cameraStats.WithRate)
	fmt.Println()
	fmt.Printf("Cases WITHOUT surveillance cameras: %d\n", cameraStats.WithoutTotal)
	fmt.Printf("  - Closed: %d\n", cameraStats.WithoutClosed)
	fmt.Printf("  - Closure rate: %.2f%%\n", cameraStats.WithoutRate)
	fmt.Println()
	fmt.Printf("ANSWER: Cases with cameras have a %.2f%% closure rate\n", cameraStats.WithRate)
	fmt.Printf("        Cases without cameras have a %.2f%% closure rate\n", cameraStats.WithoutRate)
	fmt.Printf("        Difference: %.2f percentage points\n", cameraStats.Diff)

	if cameraStats.WithRate > cameraStats.WithoutRate {
		fmt.Println("\n✓ Surveillance cameras correlate with higher case closure rates!")
	} else if cameraStats.WithRate < cameraStats.WithoutRate {
		fmt.Println("\n✗ Surprisingly, cases without cameras close at a higher rate.")
	} else {
		fmt.Println("\n→ No significant difference between camera presence and closure rate.")
	}

	fmt.Println("\n" + strings.Repeat("=", 70))
	fmt.Println("QUESTION 2: What are the most dangerous months in Baltimore,")
	fmt.Println("            and what is the average victim age by month?")
	fmt.Println(strings.Repeat("=", 70))

	fmt.Printf("\n%-12s | %10s | %15s\n", "Month", "Homicides", "Avg Victim Age")
	fmt.Println(strings.Repeat("-", 70))

	for _, stat := range monthlyStats {
		ageStr := "N/A"
		if stat.AvgAge != nil {
			ageStr = fmt.Sprintf("%.1f years", *stat.AvgAge)
		}
		fmt.Printf("%-12s | %10d | %15s\n", stat.MonthName, stat.Count, ageStr)
	}

	deadliest := monthlyStats[0]
	safest := monthlyStats[len(monthlyStats)-1]

	fmt.Println()
	fmt.Printf("ANSWER: Most dangerous month: %s with %d homicides\n", deadliest.MonthName, deadliest.Count)
	fmt.Printf("        Safest month: %s with %d homicides\n", safest.MonthName, safest.Count)

	var allAges []int
	for _, r := range records {
		if age, ok := parseAge(r.Age); ok {
			allAges = append(allAges, age)
		}
	}

	if len(allAges) > 0 {
		sum := 0
		for _, age := range allAges {
			sum += age
		}
		overallAvgAge := float64(sum) / float64(len(allAges))
		fmt.Printf("        Overall average victim age: %.1f years\n", overallAvgAge)
	}

	totalCount := 0
	for _, stat := range monthlyStats {
		totalCount += stat.Count
	}
	avgPerMonth := float64(totalCount) / 12.0

	var dangerousMonths []string
	for _, stat := range monthlyStats {
		if float64(stat.Count) > avgPerMonth {
			dangerousMonths = append(dangerousMonths, stat.MonthName)
		}
	}

	fmt.Printf("\n✓ %d months are above average (>%.1f homicides/month)\n", len(dangerousMonths), avgPerMonth)
	fmt.Printf("  Dangerous months: %s\n", strings.Join(dangerousMonths, ", "))

	fmt.Println("\n" + strings.Repeat("=", 70))
	fmt.Println("ANALYSIS COMPLETE")
	fmt.Println(strings.Repeat("=", 70) + "\n")
}

func outputCSV(records []HomicideRecord, cameraStats CameraStats, monthlyStats []MonthStats) {
	// Try to write to /output directory if in Docker, otherwise current directory
	outputPath := "analysis_summary.csv"
	if _, err := os.Stat("/output"); err == nil {
		outputPath = "/output/analysis_summary.csv"
	}
	
	file, err := os.Create(outputPath)
	if err != nil {
		fmt.Printf("Error creating CSV file: %v\n", err)
		return
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"Baltimore Homicide Analysis Report"})
	writer.Write([]string{"Total Records", strconv.Itoa(len(records))})
	writer.Write([]string{})

	writer.Write([]string{"QUESTION 1: What percentage of homicide cases with surveillance cameras get closed compared to cases without cameras?"})
	writer.Write([]string{})
	writer.Write([]string{"Camera Analysis"})
	writer.Write([]string{"Category", "Total Cases", "Cases Closed", "Closure Rate (%)"})
	writer.Write([]string{"WITH cameras", strconv.Itoa(cameraStats.WithTotal), 
		strconv.Itoa(cameraStats.WithClosed), fmt.Sprintf("%.2f", cameraStats.WithRate)})
	writer.Write([]string{"WITHOUT cameras", strconv.Itoa(cameraStats.WithoutTotal), 
		strconv.Itoa(cameraStats.WithoutClosed), fmt.Sprintf("%.2f", cameraStats.WithoutRate)})
	writer.Write([]string{"Difference (percentage points)", "", "", fmt.Sprintf("%.2f", cameraStats.Diff)})
	writer.Write([]string{})

	writer.Write([]string{"QUESTION 2: What are the most dangerous months in Baltimore and what is the average victim age by month?"})
	writer.Write([]string{})
	writer.Write([]string{"Monthly Analysis"})
	writer.Write([]string{"Month", "Homicides", "Average Victim Age"})

	for _, stat := range monthlyStats {
		ageStr := "N/A"
		if stat.AvgAge != nil {
			ageStr = fmt.Sprintf("%.1f", *stat.AvgAge)
		}
		writer.Write([]string{stat.MonthName, strconv.Itoa(stat.Count), ageStr})
	}
	writer.Write([]string{})

	totalCount := 0
	for _, stat := range monthlyStats {
		totalCount += stat.Count
	}
	avgPerMonth := float64(totalCount) / 12.0

	var dangerous []MonthStats
	for _, stat := range monthlyStats {
		if float64(stat.Count) > avgPerMonth {
			dangerous = append(dangerous, stat)
		}
	}

	if len(dangerous) > 5 {
		dangerous = dangerous[:5]
	}

	writer.Write([]string{"Top Dangerous Months"})
	writer.Write([]string{"Rank", "Month", "Homicides"})
	for i, stat := range dangerous {
		writer.Write([]string{strconv.Itoa(i + 1), stat.MonthName, strconv.Itoa(stat.Count)})
	}

	fmt.Println("\n✓ Wrote analysis CSV -> analysis_summary.csv")
}

func outputJSON(records []HomicideRecord, cameraStats CameraStats, monthlyStats []MonthStats) {
	var output JSONOutput
	output.Analysis = "Baltimore Homicide Data Analysis"
	output.DataSource = "chamspage.blogspot.com"
	output.TotalRecords = len(records)

	// Camera analysis
	output.CameraAnalysis.WithCamera.TotalCases = cameraStats.WithTotal
	output.CameraAnalysis.WithCamera.CasesClosed = cameraStats.WithClosed
	output.CameraAnalysis.WithCamera.ClosureRate = cameraStats.WithRate
	output.CameraAnalysis.WithoutCamera.TotalCases = cameraStats.WithoutTotal
	output.CameraAnalysis.WithoutCamera.CasesClosed = cameraStats.WithoutClosed
	output.CameraAnalysis.WithoutCamera.ClosureRate = cameraStats.WithoutRate
	output.CameraAnalysis.ClosureRateDifference = cameraStats.Diff

	// Monthly statistics
	for _, stat := range monthlyStats {
		output.MonthlyStatistics = append(output.MonthlyStatistics, JSONMonthly{
			Month:            stat.MonthNum,
			MonthName:        stat.MonthName,
			HomicideCount:    stat.Count,
			AverageVictimAge: stat.AvgAge,
		})
	}

	// Summary
	deadliest := monthlyStats[0]
	safest := monthlyStats[len(monthlyStats)-1]
	output.Summary.MostDangerousMonth.Month = deadliest.MonthName
	output.Summary.MostDangerousMonth.Homicides = deadliest.Count
	output.Summary.SafestMonth.Month = safest.MonthName
	output.Summary.SafestMonth.Homicides = safest.Count

	var allAges []int
	for _, r := range records {
		if age, ok := parseAge(r.Age); ok {
			allAges = append(allAges, age)
		}
	}
	if len(allAges) > 0 {
		sum := 0
		for _, age := range allAges {
			sum += age
		}
		avg := float64(sum) / float64(len(allAges))
		output.Summary.OverallAverageVictimAge = &avg
	}

	jsonData, err := json.MarshalIndent(output, "", "  ")
	if err != nil {
		fmt.Printf("Error creating JSON: %v\n", err)
		return
	}

	err = os.WriteFile("analysis_summary.json", jsonData, 0644)
	if err != nil {
		fmt.Printf("Error writing JSON file: %v\n", err)
		return
	}

	fmt.Println("\n✓ Wrote analysis JSON -> analysis_summary.json")
}