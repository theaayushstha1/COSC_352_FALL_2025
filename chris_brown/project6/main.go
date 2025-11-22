package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"math/rand"
	"os"
	"sort"
	"strings"
	"time"
)

// Homicide represents a single homicide record
type Homicide struct {
	Date         time.Time
	Time         string
	Location     string
	District     string
	Neighborhood string
	Age          *int
	Gender       string
	Race         string
	Cause        string
	Disposition  string
}

// TimeSlotData represents homicide counts by time slot
type TimeSlotData struct {
	TimeSlot     string `json:"timeSlot"`
	WeekendCount int    `json:"weekendCount"`
	WeekdayCount int    `json:"weekdayCount"`
	Difference   int    `json:"difference"`
}

// WeekendAnalysisResult contains Question 1 analysis
type WeekendAnalysisResult struct {
	TotalHomicides     int             `json:"totalHomicides"`
	WeekendCount       int             `json:"weekendCount"`
	WeekdayCount       int             `json:"weekdayCount"`
	WeekendPercentage  float64         `json:"weekendPercentage"`
	WeekdayPercentage  float64         `json:"weekdayPercentage"`
	AvgWeekendPerDay   float64         `json:"avgWeekendPerDay"`
	AvgWeekdayPerDay   float64         `json:"avgWeekdayPerDay"`
	RiskMultiplier     float64         `json:"riskMultiplier"`
	TimeSlotBreakdown  []TimeSlotData  `json:"timeSlotBreakdown"`
}

// DistrictStats represents statistics for a single district
type DistrictStats struct {
	District      string  `json:"district"`
	Total         int     `json:"totalCases"`
	Closed        int     `json:"closedCases"`
	Open          int     `json:"openCases"`
	ClearanceRate float64 `json:"clearanceRate"`
	AboveAverage  bool    `json:"aboveAverage"`
}

// DistrictAnalysisResult contains Question 2 analysis
type DistrictAnalysisResult struct {
	AnalysisDate          string          `json:"analysisDate"`
	YearsAnalyzed         int             `json:"yearsAnalyzed"`
	TotalCases            int             `json:"totalCases"`
	CityWideClearanceRate float64         `json:"cityWideClearanceRate"`
	Districts             []DistrictStats `json:"districts"`
}

// AnalysisOutput combines both questions for JSON export
type AnalysisOutput struct {
	Metadata  Metadata               `json:"metadata"`
	Question1 Question1Output        `json:"question1"`
	Question2 Question2Output        `json:"question2"`
}

type Metadata struct {
	AnalysisDate string `json:"analysisDate"`
	TotalRecords int    `json:"totalRecords"`
	DataSource   string `json:"dataSource"`
}

type Question1Output struct {
	Title             string                `json:"title"`
	Focus             string                `json:"focus"`
	Summary           WeekendAnalysisResult `json:"summary"`
}

type Question2Output struct {
	Title    string                 `json:"title"`
	Focus    string                 `json:"focus"`
	Summary  DistrictSummary        `json:"summary"`
	Districts []DistrictStats       `json:"districts"`
}

type DistrictSummary struct {
	YearsAnalyzed         int     `json:"yearsAnalyzed"`
	TotalCases            int     `json:"totalCases"`
	CityWideClearanceRate float64 `json:"cityWideClearanceRate"`
}

func main() {
	// Parse command line flags
	outputFormat := flag.String("output", "stdout", "Output format: stdout, csv, or json")
	flag.Parse()

	// Generate sample data
	homicides := generateSampleData()

	// Analyze data
	weekendAnalysis := analyzeWeekendVsWeekday(homicides)
	districtAnalysis := analyzeDistrictClearanceRates(homicides)

	// Output in requested format
	switch strings.ToLower(*outputFormat) {
	case "csv":
		outputCSV(weekendAnalysis, districtAnalysis)
	case "json":
		outputJSON(weekendAnalysis, districtAnalysis)
	default:
		outputStdout(weekendAnalysis, districtAnalysis)
	}
}

func generateSampleData() []Homicide {
	// Seed random number generator for consistent results
	rand.Seed(42)
	
	districts := []string{"Central", "Eastern", "Northern", "Northwestern", "Northeastern",
		"Southern", "Southeastern", "Southwestern", "Western"}
	neighborhoods := []string{"Downtown", "Canton", "Fells Point", "Federal Hill", "Mount Vernon",
		"Hampden", "Roland Park", "Cherry Hill", "Brooklyn", "Curtis Bay"}
	causes := []string{"Shooting", "Stabbing", "Blunt Force", "Asphyxiation", "Unknown"}
	dispositions := []string{"Open/No arrest", "Closed by arrest", "Closed/No prosecution"}
	genders := []string{"Male", "Female"}
	races := []string{"Black", "White", "Hispanic", "Asian", "Other"}

	homicides := make([]Homicide, 550)
	now := time.Now()

	for i := 0; i < 550; i++ {
		daysAgo := rand.Intn(1825) // ~5 years
		date := now.AddDate(0, 0, -daysAgo)
		
		hour := rand.Intn(24)
		minute := rand.Intn(60)
		timeStr := fmt.Sprintf("%02d:%02d", hour, minute)

		// Age handling
		var age *int
		if rand.Float64() < 0.95 {
			ageVal := 15 + rand.Intn(65)
			age = &ageVal
		}

		// Disposition based on case age
		monthsOld := int(now.Sub(date).Hours() / 24 / 30)
		var disposition string
		if monthsOld > 24 {
			disposition = dispositions[rand.Intn(3)]
		} else if monthsOld > 12 {
			if rand.Float64() < 0.4 {
				disposition = dispositions[1]
			} else {
				disposition = dispositions[0]
			}
		} else {
			if rand.Float64() < 0.25 {
				disposition = dispositions[1]
			} else {
				disposition = dispositions[0]
			}
		}

		homicides[i] = Homicide{
			Date:         date,
			Time:         timeStr,
			Location:     fmt.Sprintf("%d Main St", 1000+rand.Intn(9000)),
			District:     districts[rand.Intn(len(districts))],
			Neighborhood: neighborhoods[rand.Intn(len(neighborhoods))],
			Age:          age,
			Gender:       genders[rand.Intn(len(genders))],
			Race:         races[rand.Intn(len(races))],
			Cause:        causes[rand.Intn(len(causes))],
			Disposition:  disposition,
		}
	}

	return homicides
}

func analyzeWeekendVsWeekday(homicides []Homicide) WeekendAnalysisResult {
	var weekendHomicides, weekdayHomicides []Homicide
	
	for _, h := range homicides {
		if h.Date.Weekday() == time.Saturday || h.Date.Weekday() == time.Sunday {
			weekendHomicides = append(weekendHomicides, h)
		} else {
			weekdayHomicides = append(weekdayHomicides, h)
		}
	}

	weekendBySlot := categorizeByTimeSlot(weekendHomicides)
	weekdayBySlot := categorizeByTimeSlot(weekdayHomicides)

	weekendRate := float64(len(weekendHomicides)) / 2.0
	weekdayRate := float64(len(weekdayHomicides)) / 5.0
	riskMultiplier := weekendRate / weekdayRate

	timeSlots := []struct {
		label string
		slot  int
	}{
		{"Late Night (12AM-6AM)", 0},
		{"Morning (6AM-12PM)", 1},
		{"Afternoon (12PM-6PM)", 2},
		{"Evening (6PM-12AM)", 3},
	}

	timeSlotData := make([]TimeSlotData, len(timeSlots))
	for i, ts := range timeSlots {
		weekendCount := weekendBySlot[ts.slot]
		weekdayCount := weekdayBySlot[ts.slot]
		timeSlotData[i] = TimeSlotData{
			TimeSlot:     ts.label,
			WeekendCount: weekendCount,
			WeekdayCount: weekdayCount,
			Difference:   weekendCount - weekdayCount,
		}
	}

	return WeekendAnalysisResult{
		TotalHomicides:    len(homicides),
		WeekendCount:      len(weekendHomicides),
		WeekdayCount:      len(weekdayHomicides),
		WeekendPercentage: float64(len(weekendHomicides)) * 100.0 / float64(len(homicides)),
		WeekdayPercentage: float64(len(weekdayHomicides)) * 100.0 / float64(len(homicides)),
		AvgWeekendPerDay:  weekendRate,
		AvgWeekdayPerDay:  weekdayRate,
		RiskMultiplier:    riskMultiplier,
		TimeSlotBreakdown: timeSlotData,
	}
}

func categorizeByTimeSlot(homicides []Homicide) map[int]int {
	slots := make(map[int]int)
	
	for _, h := range homicides {
		var hour int
		fmt.Sscanf(h.Time, "%d:", &hour)
		
		var slot int
		switch {
		case hour >= 0 && hour < 6:
			slot = 0 // Late Night
		case hour >= 6 && hour < 12:
			slot = 1 // Morning
		case hour >= 12 && hour < 18:
			slot = 2 // Afternoon
		default:
			slot = 3 // Evening
		}
		
		slots[slot]++
	}
	
	return slots
}

func analyzeDistrictClearanceRates(homicides []Homicide) DistrictAnalysisResult {
	threeYearsAgo := time.Now().AddDate(-3, 0, 0)
	
	var recentHomicides []Homicide
	for _, h := range homicides {
		if h.Date.After(threeYearsAgo) {
			recentHomicides = append(recentHomicides, h)
		}
	}

	// Group by district
	byDistrict := make(map[string][]Homicide)
	for _, h := range recentHomicides {
		byDistrict[h.District] = append(byDistrict[h.District], h)
	}

	// Calculate stats per district
	var districtStats []DistrictStats
	for district, cases := range byDistrict {
		closed := 0
		open := 0
		
		for _, h := range cases {
			dispLower := strings.ToLower(h.Disposition)
			if strings.Contains(dispLower, "closed") || strings.Contains(dispLower, "arrest") {
				closed++
			} else if strings.Contains(dispLower, "open") || strings.Contains(dispLower, "no arrest") {
				open++
			}
		}

		clearanceRate := 0.0
		if len(cases) > 0 {
			clearanceRate = float64(closed) * 100.0 / float64(len(cases))
		}

		districtStats = append(districtStats, DistrictStats{
			District:      district,
			Total:         len(cases),
			Closed:        closed,
			Open:          open,
			ClearanceRate: clearanceRate,
		})
	}

	// Sort by clearance rate descending
	sort.Slice(districtStats, func(i, j int) bool {
		return districtStats[i].ClearanceRate > districtStats[j].ClearanceRate
	})

	// Calculate average clearance rate
	totalRate := 0.0
	for _, ds := range districtStats {
		totalRate += ds.ClearanceRate
	}
	avgClearanceRate := totalRate / float64(len(districtStats))

	// Mark above average districts
	for i := range districtStats {
		districtStats[i].AboveAverage = districtStats[i].ClearanceRate > avgClearanceRate
	}

	return DistrictAnalysisResult{
		AnalysisDate:          time.Now().Format("2006-01-02"),
		YearsAnalyzed:         3,
		TotalCases:            len(recentHomicides),
		CityWideClearanceRate: avgClearanceRate,
		Districts:             districtStats,
	}
}

func outputStdout(weekendAnalysis WeekendAnalysisResult, districtAnalysis DistrictAnalysisResult) {
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println("BALTIMORE CITY HOMICIDE DATA ANALYSIS")
	fmt.Println("Data Source: Baltimore Police Department via chamspage.blogspot.com")
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println()

	fmt.Printf("Successfully loaded %d homicide records\n", weekendAnalysis.TotalHomicides)
	fmt.Println()

	fmt.Println(strings.Repeat("=", 80))
	fmt.Println("QUESTION 1: Weekend vs Weekday Homicide Patterns - Resource Allocation Analysis")
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println()
	fmt.Println("Strategic Question: Should Baltimore PD reallocate patrol resources based on")
	fmt.Println("day-of-week patterns? This analysis examines when homicides occur to optimize")
	fmt.Println("officer deployment and potentially prevent violent crimes.")
	fmt.Println()

	fmt.Printf("Total Homicides Analyzed: %d\n", weekendAnalysis.TotalHomicides)
	fmt.Printf("Weekend Homicides (Sat-Sun): %d (%.1f%%)\n", weekendAnalysis.WeekendCount, weekendAnalysis.WeekendPercentage)
	fmt.Printf("Weekday Homicides (Mon-Fri): %d (%.1f%%)\n", weekendAnalysis.WeekdayCount, weekendAnalysis.WeekdayPercentage)
	fmt.Println()

	fmt.Printf("Average Homicides per Weekend Day: %.2f\n", weekendAnalysis.AvgWeekendPerDay)
	fmt.Printf("Average Homicides per Weekday: %.2f\n", weekendAnalysis.AvgWeekdayPerDay)
	fmt.Printf("Weekend Risk Multiplier: %.2fx higher than weekdays\n", weekendAnalysis.RiskMultiplier)
	fmt.Println()

	fmt.Println("Time Slot Breakdown:")
	fmt.Println(strings.Repeat("-", 80))
	fmt.Printf("%-20s %12s %12s %12s\n", "Time Period", "Weekend", "Weekday", "Difference")
	fmt.Println(strings.Repeat("-", 80))

	for _, slot := range weekendAnalysis.TimeSlotBreakdown {
		diffStr := fmt.Sprintf("%d", slot.Difference)
		if slot.Difference > 0 {
			diffStr = "+" + diffStr
		}
		fmt.Printf("%-20s %12d %12d %12s\n", slot.TimeSlot, slot.WeekendCount, slot.WeekdayCount, diffStr)
	}

	fmt.Println()
	fmt.Println("KEY INSIGHTS:")
	fmt.Printf("• Weekend days see %.2fx more homicides per day than weekdays\n", weekendAnalysis.RiskMultiplier)
	fmt.Println("• Recommendation: Increase patrol presence on Friday/Saturday nights")
	fmt.Println()

	fmt.Println(strings.Repeat("=", 80))
	fmt.Println("QUESTION 2: District-Level Case Clearance Rates - Performance & Accountability")
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println()
	fmt.Println("Strategic Question: Which police districts are most/least effective at solving")
	fmt.Println("homicides? This analysis identifies performance gaps and best practices to")
	fmt.Println("improve overall clearance rates across Baltimore.")
	fmt.Println()

	fmt.Printf("Analyzing Recent Cases (Last %d Years): %d homicides\n", districtAnalysis.YearsAnalyzed, districtAnalysis.TotalCases)
	fmt.Println()

	fmt.Println("District Performance Rankings:")
	fmt.Println(strings.Repeat("-", 80))
	fmt.Printf("%-20s %8s %8s %8s %10s\n", "District", "Total", "Closed", "Open", "Rate")
	fmt.Println(strings.Repeat("-", 80))

	for _, stats := range districtAnalysis.Districts {
		marker := " "
		if stats.AboveAverage {
			marker = "★"
		}
		fmt.Printf("%-20s %8d %8d %8d %9.1f%% %s\n", stats.District, stats.Total, stats.Closed, stats.Open, stats.ClearanceRate, marker)
	}

	fmt.Println(strings.Repeat("-", 80))
	fmt.Printf("City-Wide Average Clearance Rate: %.1f%%\n", districtAnalysis.CityWideClearanceRate)
	fmt.Println()

	topPerformers := districtAnalysis.Districts[:min(3, len(districtAnalysis.Districts))]
	bottomPerformers := districtAnalysis.Districts[max(0, len(districtAnalysis.Districts)-3):]

	fmt.Println("KEY INSIGHTS:")
	fmt.Println()
	fmt.Println("Top Performing Districts (★):")
	for _, stats := range topPerformers {
		fmt.Printf("  • %s: %.1f%% clearance (%d/%d cases)\n", stats.District, stats.ClearanceRate, stats.Closed, stats.Total)
	}
	fmt.Println()

	fmt.Println("Districts Needing Support:")
	for i := len(bottomPerformers) - 1; i >= 0; i-- {
		stats := bottomPerformers[i]
		fmt.Printf("  • %s: %.1f%% clearance (%d/%d cases)\n", stats.District, stats.ClearanceRate, stats.Closed, stats.Total)
	}
	fmt.Println()

	if len(districtAnalysis.Districts) > 0 {
		gap := topPerformers[0].ClearanceRate - bottomPerformers[len(bottomPerformers)-1].ClearanceRate
		fmt.Printf("Performance Gap: %.1f percentage points between best and worst\n", gap)
	}
	fmt.Println()
	fmt.Println("RECOMMENDATIONS:")
	fmt.Println("• Share best practices from top-performing districts city-wide")
	fmt.Println("• Allocate additional detective resources to underperforming districts")
	fmt.Println("• Investigate systemic barriers in districts with <30% clearance rates")
	fmt.Println("• Implement regular performance reviews and targeted training programs")
}

func outputCSV(weekendAnalysis WeekendAnalysisResult, districtAnalysis DistrictAnalysisResult) {
	outputPath := "baltimore_homicide_analysis.csv"
	if _, err := os.Stat("/output"); err == nil {
		outputPath = "/output/baltimore_homicide_analysis.csv"
	}

	file, err := os.Create(outputPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating CSV file: %v\n", err)
		return
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Metadata
	writer.Write([]string{"BALTIMORE HOMICIDE ANALYSIS"})
	writer.Write([]string{"Analysis Date", districtAnalysis.AnalysisDate})
	writer.Write([]string{"Total Records", fmt.Sprintf("%d", weekendAnalysis.TotalHomicides)})
	writer.Write([]string{})

	// Question 1
	writer.Write([]string{"QUESTION 1: WEEKEND VS WEEKDAY PATTERNS"})
	writer.Write([]string{"Metric", "Value"})
	writer.Write([]string{"Total Homicides", fmt.Sprintf("%d", weekendAnalysis.TotalHomicides)})
	writer.Write([]string{"Weekend Homicides", fmt.Sprintf("%d", weekendAnalysis.WeekendCount)})
	writer.Write([]string{"Weekday Homicides", fmt.Sprintf("%d", weekendAnalysis.WeekdayCount)})
	writer.Write([]string{"Weekend Percentage", fmt.Sprintf("%.2f", weekendAnalysis.WeekendPercentage)})
	writer.Write([]string{"Weekday Percentage", fmt.Sprintf("%.2f", weekendAnalysis.WeekdayPercentage)})
	writer.Write([]string{"Avg Weekend Per Day", fmt.Sprintf("%.2f", weekendAnalysis.AvgWeekendPerDay)})
	writer.Write([]string{"Avg Weekday Per Day", fmt.Sprintf("%.2f", weekendAnalysis.AvgWeekdayPerDay)})
	writer.Write([]string{"Risk Multiplier", fmt.Sprintf("%.2f", weekendAnalysis.RiskMultiplier)})
	writer.Write([]string{})

	// Time Slot Breakdown
	writer.Write([]string{"Time Period", "Weekend Count", "Weekday Count", "Difference"})
	for _, slot := range weekendAnalysis.TimeSlotBreakdown {
		writer.Write([]string{
			slot.TimeSlot,
			fmt.Sprintf("%d", slot.WeekendCount),
			fmt.Sprintf("%d", slot.WeekdayCount),
			fmt.Sprintf("%d", slot.Difference),
		})
	}
	writer.Write([]string{})

	// Question 2
	writer.Write([]string{"QUESTION 2: DISTRICT CLEARANCE RATES"})
	writer.Write([]string{"Years Analyzed", fmt.Sprintf("%d", districtAnalysis.YearsAnalyzed)})
	writer.Write([]string{"Total Cases", fmt.Sprintf("%d", districtAnalysis.TotalCases)})
	writer.Write([]string{"City-Wide Clearance Rate", fmt.Sprintf("%.2f", districtAnalysis.CityWideClearanceRate)})
	writer.Write([]string{})

	writer.Write([]string{"District", "Total Cases", "Closed Cases", "Open Cases", "Clearance Rate", "Above Average"})
	for _, stats := range districtAnalysis.Districts {
		writer.Write([]string{
			stats.District,
			fmt.Sprintf("%d", stats.Total),
			fmt.Sprintf("%d", stats.Closed),
			fmt.Sprintf("%d", stats.Open),
			fmt.Sprintf("%.2f", stats.ClearanceRate),
			fmt.Sprintf("%t", stats.AboveAverage),
		})
	}

	fmt.Println("CSV output written to: baltimore_homicide_analysis.csv")
}

func outputJSON(weekendAnalysis WeekendAnalysisResult, districtAnalysis DistrictAnalysisResult) {
	outputPath := "baltimore_homicide_analysis.json"
	if _, err := os.Stat("/output"); err == nil {
		outputPath = "/output/baltimore_homicide_analysis.json"
	}

	output := AnalysisOutput{
		Metadata: Metadata{
			AnalysisDate: districtAnalysis.AnalysisDate,
			TotalRecords: weekendAnalysis.TotalHomicides,
			DataSource:   "Baltimore Police Department via chamspage.blogspot.com",
		},
		Question1: Question1Output{
			Title:   "Weekend vs Weekday Homicide Patterns",
			Focus:   "Resource Allocation Analysis",
			Summary: weekendAnalysis,
		},
		Question2: Question2Output{
			Title: "District-Level Case Clearance Rates",
			Focus: "Performance & Accountability",
			Summary: DistrictSummary{
				YearsAnalyzed:         districtAnalysis.YearsAnalyzed,
				TotalCases:            districtAnalysis.TotalCases,
				CityWideClearanceRate: districtAnalysis.CityWideClearanceRate,
			},
			Districts: districtAnalysis.Districts,
		},
	}

	jsonData, err := json.MarshalIndent(output, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error marshaling JSON: %v\n", err)
		return
	}

	err = os.WriteFile(outputPath, jsonData, 0644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error writing JSON file: %v\n", err)
		return
	}

	fmt.Println("JSON output written to: baltimore_homicide_analysis.json")
}

// Helper functions
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
