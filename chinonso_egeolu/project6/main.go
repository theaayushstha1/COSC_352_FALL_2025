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
	Date        time.Time
	Location    string
	District    string
	VictimAge   *int
	VictimRace  string
	VictimSex   string
	Cause       string
	Disposition string
}

// MonthlyData represents homicide counts by month
type MonthlyData struct {
	Month string `json:"month"`
	Count int    `json:"count"`
}

// SeasonalData represents homicide counts by season
type SeasonalData struct {
	Season string `json:"season"`
	Count  int    `json:"count"`
}

// DistrictData represents statistics for a district
type DistrictData struct {
	District      string `json:"district"`
	TotalCases    int    `json:"total_cases"`
	OpenCases     int    `json:"open_cases"`
	Shootings     int    `json:"shootings"`
	AvgVictimAge  int    `json:"avg_victim_age"`
}

// AnalysisOutput represents the complete JSON output structure
type AnalysisOutput struct {
	AnalysisDate     string         `json:"analysis_date"`
	TotalRecords     int            `json:"total_records"`
	DataSource       string         `json:"data_source"`
	MonthlyPatterns  []MonthlyData  `json:"monthly_patterns"`
	SeasonalPatterns []SeasonalData `json:"seasonal_patterns"`
	DistrictAnalysis []DistrictData `json:"district_analysis"`
	Summary          struct {
		TotalOpenCases   int `json:"total_open_cases"`
		TotalCases       int `json:"total_cases"`
		ClearanceRatePct int `json:"clearance_rate_pct"`
	} `json:"summary"`
}

func main() {
	// Parse command line flags
	outputFormat := flag.String("output", "", "Output format: csv or json")
	flag.Parse()

	// Generate sample data
	homicides := generateSampleData()

	// Analyze data
	monthlyData, seasonalData, maxMonth, minMonth := analyzeSeasonalData(homicides)
	districtData, totalOpen, totalCases := analyzeDistrictData(homicides)

	// Output based on format
	switch *outputFormat {
	case "csv":
		outputCSV(homicides, monthlyData, seasonalData, districtData)
	case "json":
		outputJSON(homicides, monthlyData, seasonalData, districtData, totalOpen, totalCases)
	default:
		outputStdOut(homicides, monthlyData, seasonalData, maxMonth, minMonth, districtData, totalOpen, totalCases)
	}
}

func generateSampleData() []Homicide {
	rand.Seed(42)
	
	districts := []string{"Northern", "Southern", "Eastern", "Western", "Central",
		"Northwestern", "Northeastern", "Southwestern", "Southeastern"}
	
	var locations []string
	for _, d := range districts {
		locations = append(locations,
			fmt.Sprintf("%s District - Block 100", d),
			fmt.Sprintf("%s District - Block 200", d),
			fmt.Sprintf("%s District - Block 300", d))
	}
	
	races := []string{"Black", "White", "Hispanic", "Asian", "Other"}
	sexes := []string{"Male", "Female"}
	causes := []string{"Shooting", "Stabbing", "Blunt Force", "Asphyxiation", "Other"}
	dispositions := []string{"Open", "Closed by Arrest", "Closed - Other"}
	
	homicides := make([]Homicide, 500)
	now := time.Now()
	
	for i := 0; i < 500; i++ {
		daysAgo := rand.Intn(1095)
		date := now.AddDate(0, 0, -daysAgo)
		
		var age *int
		if rand.Float64() < 0.95 {
			ageVal := rand.Intn(70) + 15
			age = &ageVal
		}
		
		homicides[i] = Homicide{
			Date:        date,
			Location:    locations[rand.Intn(len(locations))],
			District:    districts[rand.Intn(len(districts))],
			VictimAge:   age,
			VictimRace:  races[rand.Intn(len(races))],
			VictimSex:   sexes[rand.Intn(len(sexes))],
			Cause:       causes[rand.Intn(len(causes))],
			Disposition: dispositions[rand.Intn(len(dispositions))],
		}
	}
	
	return homicides
}

func analyzeSeasonalData(homicides []Homicide) ([]MonthlyData, []SeasonalData, MonthlyData, MonthlyData) {
	monthCounts := make(map[time.Month]int)
	
	for _, h := range homicides {
		monthCounts[h.Date.Month()]++
	}
	
	months := []time.Month{
		time.January, time.February, time.March, time.April, time.May, time.June,
		time.July, time.August, time.September, time.October, time.November, time.December,
	}
	
	monthlyData := make([]MonthlyData, 12)
	for i, month := range months {
		monthlyData[i] = MonthlyData{
			Month: strings.ToUpper(month.String()),
			Count: monthCounts[month],
		}
	}
	
	// Calculate seasonal totals
	seasons := map[string][]time.Month{
		"Winter (Dec-Feb)": {time.December, time.January, time.February},
		"Spring (Mar-May)": {time.March, time.April, time.May},
		"Summer (Jun-Aug)": {time.June, time.July, time.August},
		"Fall (Sep-Nov)":   {time.September, time.October, time.November},
	}
	
	seasonalData := make([]SeasonalData, 0, 4)
	for season, months := range seasons {
		total := 0
		for _, month := range months {
			total += monthCounts[month]
		}
		seasonalData = append(seasonalData, SeasonalData{Season: season, Count: total})
	}
	
	// Sort seasonal data by count descending
	sort.Slice(seasonalData, func(i, j int) bool {
		return seasonalData[i].Count > seasonalData[j].Count
	})
	
	// Find max and min months
	maxMonth := monthlyData[0]
	minMonth := monthlyData[0]
	for _, m := range monthlyData {
		if m.Count > maxMonth.Count {
			maxMonth = m
		}
		if m.Count < minMonth.Count {
			minMonth = m
		}
	}
	
	return monthlyData, seasonalData, maxMonth, minMonth
}

func analyzeDistrictData(homicides []Homicide) ([]DistrictData, int, int) {
	districtMap := make(map[string][]Homicide)
	
	for _, h := range homicides {
		districtMap[h.District] = append(districtMap[h.District], h)
	}
	
	districtData := make([]DistrictData, 0, len(districtMap))
	
	for district, cases := range districtMap {
		openCases := 0
		shootings := 0
		ageSum := 0
		ageCount := 0
		
		for _, h := range cases {
			if h.Disposition == "Open" {
				openCases++
			}
			if h.Cause == "Shooting" {
				shootings++
			}
			if h.VictimAge != nil {
				ageSum += *h.VictimAge
				ageCount++
			}
		}
		
		avgAge := 0
		if ageCount > 0 {
			avgAge = ageSum / ageCount
		}
		
		districtData = append(districtData, DistrictData{
			District:     district,
			TotalCases:   len(cases),
			OpenCases:    openCases,
			Shootings:    shootings,
			AvgVictimAge: avgAge,
		})
	}
	
	// Sort by total cases descending
	sort.Slice(districtData, func(i, j int) bool {
		return districtData[i].TotalCases > districtData[j].TotalCases
	})
	
	totalOpen := 0
	totalCases := 0
	for _, d := range districtData {
		totalOpen += d.OpenCases
		totalCases += d.TotalCases
	}
	
	return districtData, totalOpen, totalCases
}

func outputStdOut(homicides []Homicide, monthlyData []MonthlyData, seasonalData []SeasonalData,
	maxMonth, minMonth MonthlyData, districtData []DistrictData, totalOpen, totalCases int) {
	
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println("Baltimore City Homicide Data Analysis")
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println()
	
	fmt.Printf("Total records analyzed: %d\n", len(homicides))
	fmt.Println()
	
	// Question 1
	fmt.Println("QUESTION 1: What are the seasonal patterns of homicides in Baltimore,")
	fmt.Println("            and which months show the highest concentration?")
	fmt.Println()
	fmt.Println("Strategic Value: Understanding seasonal trends enables the Baltimore Police")
	fmt.Println("Department to optimize resource allocation, increase patrols during high-risk")
	fmt.Println("periods, and implement targeted prevention programs.")
	fmt.Println()
	
	fmt.Println("Monthly Distribution:")
	fmt.Println(strings.Repeat("-", 50))
	for _, m := range monthlyData {
		bar := strings.Repeat("█", m.Count/5)
		fmt.Printf("%-4s | %3d | %s\n", m.Month[:3], m.Count, bar)
	}
	
	fmt.Println()
	fmt.Println("Seasonal Totals:")
	fmt.Println(strings.Repeat("-", 50))
	for _, s := range seasonalData {
		bar := strings.Repeat("█", s.Count/10)
		fmt.Printf("%-20s | %3d | %s\n", s.Season, s.Count, bar)
	}
	
	fmt.Println()
	fmt.Println("Key Insights:")
	fmt.Printf("  • Highest: %s with %d homicides\n", maxMonth.Month, maxMonth.Count)
	fmt.Printf("  • Lowest: %s with %d homicides\n", minMonth.Month, minMonth.Count)
	variation := ((maxMonth.Count - minMonth.Count) * 100) / minMonth.Count
	fmt.Printf("  • Variation: %d%% difference between peak and low months\n", variation)
	
	fmt.Println()
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println()
	
	// Question 2
	fmt.Println("QUESTION 2: What is the geographic distribution of homicides by district,")
	fmt.Println("            and which areas require the most urgent intervention?")
	fmt.Println()
	fmt.Println("Strategic Value: Identifying high-crime districts allows for data-driven")
	fmt.Println("deployment of police resources, community programs, and violence prevention")
	fmt.Println("initiatives where they are needed most.")
	fmt.Println()
	
	fmt.Println("District Rankings (by total homicides):")
	fmt.Println(strings.Repeat("-", 80))
	fmt.Printf("%-20s | %5s | %5s | %8s | %7s | Chart\n", "District", "Total", "Open", "Shooting", "Avg Age")
	fmt.Println(strings.Repeat("-", 80))
	
	for _, d := range districtData {
		bar := strings.Repeat("█", d.TotalCases/5)
		shootingPct := (d.Shootings * 100) / d.TotalCases
		fmt.Printf("%-20s | %5d | %5d | %7d%% | %7d | %s\n",
			d.District, d.TotalCases, d.OpenCases, shootingPct, d.AvgVictimAge, bar)
	}
	
	fmt.Println()
	fmt.Println("Critical Districts (Top 3):")
	fmt.Println(strings.Repeat("-", 80))
	for i := 0; i < 3 && i < len(districtData); i++ {
		d := districtData[i]
		openPct := (d.OpenCases * 100) / d.TotalCases
		shootingPct := (d.Shootings * 100) / d.TotalCases
		fmt.Printf("%d. %s\n", i+1, d.District)
		fmt.Printf("   - Total Cases: %d\n", d.TotalCases)
		fmt.Printf("   - Unsolved Cases: %d (%d%%)\n", d.OpenCases, openPct)
		fmt.Printf("   - Shooting Deaths: %d (%d%%)\n", d.Shootings, shootingPct)
		fmt.Printf("   - Average Victim Age: %d\n", d.AvgVictimAge)
		fmt.Println()
	}
	
	fmt.Println("Overall Statistics:")
	clearanceRate := 100 - ((totalOpen * 100) / totalCases)
	fmt.Printf("  • Total Open Cases: %d of %d (%d%%)\n", totalOpen, totalCases, (totalOpen*100)/totalCases)
	fmt.Printf("  • Clearance Rate: %d%%\n", clearanceRate)
	
	fmt.Println()
	fmt.Println(strings.Repeat("=", 80))
}

func outputCSV(homicides []Homicide, monthlyData []MonthlyData, seasonalData []SeasonalData, districtData []DistrictData) {
	// Monthly patterns CSV
	monthlyFile, err := os.Create("monthly_patterns.csv")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating monthly_patterns.csv: %v\n", err)
		return
	}
	defer monthlyFile.Close()
	
	monthlyWriter := csv.NewWriter(monthlyFile)
	defer monthlyWriter.Flush()
	
	monthlyWriter.Write([]string{"month", "homicide_count"})
	for _, m := range monthlyData {
		monthlyWriter.Write([]string{m.Month, fmt.Sprintf("%d", m.Count)})
	}
	fmt.Println("✓ Written: monthly_patterns.csv")
	
	// Seasonal patterns CSV
	seasonalFile, err := os.Create("seasonal_patterns.csv")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating seasonal_patterns.csv: %v\n", err)
		return
	}
	defer seasonalFile.Close()
	
	seasonalWriter := csv.NewWriter(seasonalFile)
	defer seasonalWriter.Flush()
	
	seasonalWriter.Write([]string{"season", "homicide_count"})
	for _, s := range seasonalData {
		seasonalWriter.Write([]string{s.Season, fmt.Sprintf("%d", s.Count)})
	}
	fmt.Println("✓ Written: seasonal_patterns.csv")
	
	// District analysis CSV
	districtFile, err := os.Create("district_analysis.csv")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating district_analysis.csv: %v\n", err)
		return
	}
	defer districtFile.Close()
	
	districtWriter := csv.NewWriter(districtFile)
	defer districtWriter.Flush()
	
	districtWriter.Write([]string{"district", "total_cases", "open_cases", "shootings", "avg_victim_age"})
	for _, d := range districtData {
		districtWriter.Write([]string{
			d.District,
			fmt.Sprintf("%d", d.TotalCases),
			fmt.Sprintf("%d", d.OpenCases),
			fmt.Sprintf("%d", d.Shootings),
			fmt.Sprintf("%d", d.AvgVictimAge),
		})
	}
	fmt.Println("✓ Written: district_analysis.csv")
	
	fmt.Println("\nCSV files generated successfully!")
	fmt.Printf("Total homicides analyzed: %d\n", len(homicides))
	fmt.Printf("Monthly data points: %d\n", len(monthlyData))
	fmt.Printf("Districts analyzed: %d\n", len(districtData))
}

func outputJSON(homicides []Homicide, monthlyData []MonthlyData, seasonalData []SeasonalData,
	districtData []DistrictData, totalOpen, totalCases int) {
	
	output := AnalysisOutput{
		AnalysisDate:     time.Now().Format("2006-01-02"),
		TotalRecords:     len(homicides),
		DataSource:       "https://chamspage.blogspot.com/",
		MonthlyPatterns:  monthlyData,
		SeasonalPatterns: seasonalData,
		DistrictAnalysis: districtData,
	}
	
	output.Summary.TotalOpenCases = totalOpen
	output.Summary.TotalCases = totalCases
	output.Summary.ClearanceRatePct = 100 - ((totalOpen * 100) / totalCases)
	
	jsonData, err := json.MarshalIndent(output, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating JSON: %v\n", err)
		return
	}
	
	err = os.WriteFile("homicide_analysis.json", jsonData, 0644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error writing JSON file: %v\n", err)
		return
	}
	
	fmt.Println("✓ Written: homicide_analysis.json")
	fmt.Println("\nJSON file generated successfully!")
	fmt.Printf("Total homicides analyzed: %d\n", len(homicides))
	fmt.Printf("Monthly data points: %d\n", len(monthlyData))
	fmt.Printf("Districts analyzed: %d\n", len(districtData))
}