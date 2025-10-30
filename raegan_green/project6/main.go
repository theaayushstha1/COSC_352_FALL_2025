package main

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
)

// HomicideRecord represents a single homicide case
type HomicideRecord struct {
	Date       string `json:"date"`
	Name       string `json:"name"`
	Age        int    `json:"age"`
	Address    string `json:"address"`
	Year       int    `json:"year"`
	CaseClosed bool   `json:"caseClosed"`
}

// AnalysisResults holds all computed statistics
type AnalysisResults struct {
	TotalRecords    int
	ClosureRates    []ClosureRate
	AgeGroupStats   []AgeGroupStat
	YouthStats      YouthStatistics
	TopAges         []AgeStat
}

// ClosureRate represents closure statistics for a year
type ClosureRate struct {
	Year              int `json:"year"`
	TotalCases        int `json:"totalCases"`
	ClosedCases       int `json:"closedCases"`
	OpenCases         int `json:"openCases"`
	ClosureRatePercent int `json:"closureRatePercent"`
}

// AgeGroupStat represents statistics for an age bracket
type AgeGroupStat struct {
	AgeGroup          string `json:"ageGroup"`
	Count             int    `json:"count"`
	PercentageOfTotal int    `json:"percentageOfTotal"`
}

// YouthStatistics focuses on victims under 18
type YouthStatistics struct {
	Children        int `json:"children"`
	Teens           int `json:"teens"`
	TotalYouth      int `json:"totalYouth"`
	YouthPercentage int `json:"youthPercentage"`
}

// AgeStat represents victim count for a specific age
type AgeStat struct {
	Age   int `json:"age"`
	Count int `json:"count"`
}

// Metadata for JSON output
type Metadata struct {
	GeneratedDate string `json:"generatedDate"`
	TotalRecords  int    `json:"totalRecords"`
	Source        string `json:"source"`
}

// JSONOutput represents the complete JSON structure
type JSONOutput struct {
	Metadata            Metadata        `json:"metadata"`
	ClosureRates        []ClosureRate   `json:"closureRates"`
	AgeGroupStatistics  []AgeGroupStat  `json:"ageGroupStatistics"`
	YouthStatistics     YouthStatistics `json:"youthStatistics"`
	TopVictimAges       []AgeStat       `json:"topVictimAges"`
	HomicideRecords     []HomicideRecord `json:"homicideRecords"`
}

func main() {
	// Parse command line arguments
	outputFormat := "stdout"
	if len(os.Args) > 1 {
		outputFormat = strings.ToLower(os.Args[1])
	}

	// Validate output format
	validFormats := map[string]bool{"stdout": true, "csv": true, "json": true}
	if !validFormats[outputFormat] {
		fmt.Printf("Error: Invalid output format '%s'\n", outputFormat)
		fmt.Println("Valid formats: stdout, csv, json")
		os.Exit(1)
	}

	// Fetch and parse data
	records := fetchAndParseData()
	if len(records) == 0 {
		fmt.Println("ERROR: Could not fetch or parse homicide data from blog")
		fmt.Println("Please check your internet connection and try again.")
		return
	}

	// Analyze data
	results := analyzeData(records)

	// Output based on format
	switch outputFormat {
	case "stdout":
		outputStdout(results, records)
	case "csv":
		outputCSV(results, records)
	case "json":
		outputJSON(results, records)
	}
}

func fetchAndParseData() []HomicideRecord {
	fmt.Println("Fetching data from Baltimore homicide database...")
	
	url := "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html"
	
	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	// Create request
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		fmt.Printf("Error creating request: %v\n", err)
		return nil
	}

	// Set User-Agent header
	req.Header.Set("User-Agent", "Mozilla/5.0")

	// Make request
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("Error fetching data: %v\n", err)
		return nil
	}
	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Printf("Error reading response: %v\n", err)
		return nil
	}

	fmt.Println("Data fetched successfully. Parsing...")
	return parseHomicideTable(string(body))
}

func parseHomicideTable(html string) []HomicideRecord {
	records := []HomicideRecord{}

	// Extract all <td> content
	tdPattern := regexp.MustCompile(`<td>(.*?)</td>`)
	matches := tdPattern.FindAllStringSubmatch(html, -1)

	allCells := []string{}
	for _, match := range matches {
		if len(match) > 1 {
			allCells = append(allCells, extractText(match[1]))
		}
	}

	fmt.Printf("Extracting data from %d table cells...\n", len(allCells))

	// Process cells in groups of 9
	for i := 0; i+8 < len(allCells); {
		numStr := strings.TrimSpace(allCells[i])
		dateStr := strings.TrimSpace(allCells[i+1])
		nameStr := strings.TrimSpace(allCells[i+2])
		ageStr := strings.TrimSpace(allCells[i+3])
		addressStr := strings.TrimSpace(allCells[i+4])
		closedStr := strings.ToLower(strings.TrimSpace(allCells[i+8]))

		// Check if valid record
		numMatch, _ := regexp.MatchString(`^\d{3}$`, numStr)
		dateMatch, _ := regexp.MatchString(`^\d{2}/\d{2}/\d{2}$`, dateStr)

		if numMatch && dateMatch {
			age, err := strconv.Atoi(ageStr)
			if err != nil {
				age = 0
			}

			year := extractYear(dateStr)
			closed := strings.Contains(closedStr, "closed")

			if age > 0 && year >= 2020 && year <= 2025 && len(addressStr) > 3 {
				records = append(records, HomicideRecord{
					Date:       dateStr,
					Name:       nameStr,
					Age:        age,
					Address:    addressStr,
					Year:       year,
					CaseClosed: closed,
				})
			}

			i += 9
		} else {
			i++
		}
	}

	return records
}

func extractText(cell string) string {
	// Remove HTML tags
	noTags := regexp.MustCompile(`<[^>]*>`).ReplaceAllString(cell, "")
	
	// Decode HTML entities
	decoded := strings.ReplaceAll(noTags, "&nbsp;", " ")
	decoded = strings.ReplaceAll(decoded, "&amp;", "&")
	decoded = strings.ReplaceAll(decoded, "&lt;", "<")
	decoded = strings.ReplaceAll(decoded, "&gt;", ">")
	decoded = strings.ReplaceAll(decoded, "&quot;", "\"")
	
	return decoded
}

func extractYear(dateStr string) int {
	parts := strings.Split(dateStr, "/")
	if len(parts) >= 3 {
		yearPart := parts[2]
		if len(yearPart) == 2 {
			year, _ := strconv.Atoi(yearPart)
			return 2000 + year
		} else if len(yearPart) == 4 {
			year, _ := strconv.Atoi(yearPart)
			return year
		}
	}
	return 0
}

func analyzeData(records []HomicideRecord) AnalysisResults {
	// Filter records from 2022 onwards
	filteredRecords := []HomicideRecord{}
	for _, r := range records {
		if r.Year >= 2022 {
			filteredRecords = append(filteredRecords, r)
		}
	}

	// Calculate closure rates by year
	yearMap := make(map[int][]HomicideRecord)
	for _, r := range filteredRecords {
		yearMap[r.Year] = append(yearMap[r.Year], r)
	}

	closureRates := []ClosureRate{}
	for year, yearRecords := range yearMap {
		total := len(yearRecords)
		closed := 0
		for _, r := range yearRecords {
			if r.CaseClosed {
				closed++
			}
		}
		rate := 0
		if total > 0 {
			rate = (closed * 100) / total
		}

		closureRates = append(closureRates, ClosureRate{
			Year:              year,
			TotalCases:        total,
			ClosedCases:       closed,
			OpenCases:         total - closed,
			ClosureRatePercent: rate,
		})
	}

	// Sort by year
	sort.Slice(closureRates, func(i, j int) bool {
		return closureRates[i].Year < closureRates[j].Year
	})

	// Calculate age group statistics
	ageGroups := map[string][]HomicideRecord{
		"Children (0-12)":      {},
		"Teens (13-18)":        {},
		"Young Adults (19-30)": {},
		"Adults (31-50)":       {},
		"Seniors (51+)":        {},
	}

	for _, r := range records {
		if r.Age >= 0 && r.Age <= 12 {
			ageGroups["Children (0-12)"] = append(ageGroups["Children (0-12)"], r)
		} else if r.Age >= 13 && r.Age <= 18 {
			ageGroups["Teens (13-18)"] = append(ageGroups["Teens (13-18)"], r)
		} else if r.Age >= 19 && r.Age <= 30 {
			ageGroups["Young Adults (19-30)"] = append(ageGroups["Young Adults (19-30)"], r)
		} else if r.Age >= 31 && r.Age <= 50 {
			ageGroups["Adults (31-50)"] = append(ageGroups["Adults (31-50)"], r)
		} else if r.Age >= 51 {
			ageGroups["Seniors (51+)"] = append(ageGroups["Seniors (51+)"], r)
		}
	}

	ageGroupStats := []AgeGroupStat{}
	for name, group := range ageGroups {
		count := len(group)
		percent := 0
		if len(records) > 0 {
			percent = (count * 100) / len(records)
		}
		ageGroupStats = append(ageGroupStats, AgeGroupStat{
			AgeGroup:          name,
			Count:             count,
			PercentageOfTotal: percent,
		})
	}

	// Sort by count descending
	sort.Slice(ageGroupStats, func(i, j int) bool {
		return ageGroupStats[i].Count > ageGroupStats[j].Count
	})

	// Youth statistics
	childVictims := len(ageGroups["Children (0-12)"])
	teenVictims := len(ageGroups["Teens (13-18)"])
	youthTotal := childVictims + teenVictims
	youthPercent := 0
	if len(records) > 0 {
		youthPercent = (youthTotal * 100) / len(records)
	}

	youthStats := YouthStatistics{
		Children:        childVictims,
		Teens:           teenVictims,
		TotalYouth:      youthTotal,
		YouthPercentage: youthPercent,
	}

	// Top ages
	ageCount := make(map[int]int)
	for _, r := range records {
		ageCount[r.Age]++
	}

	topAges := []AgeStat{}
	for age, count := range ageCount {
		topAges = append(topAges, AgeStat{Age: age, Count: count})
	}

	sort.Slice(topAges, func(i, j int) bool {
		return topAges[i].Count > topAges[j].Count
	})

	if len(topAges) > 5 {
		topAges = topAges[:5]
	}

	return AnalysisResults{
		TotalRecords:  len(records),
		ClosureRates:  closureRates,
		AgeGroupStats: ageGroupStats,
		YouthStats:    youthStats,
		TopAges:       topAges,
	}
}

func outputStdout(results AnalysisResults, records []HomicideRecord) {
	fmt.Println("\n" + strings.Repeat("=", 80))
	fmt.Println("BALTIMORE HOMICIDE STATISTICS ANALYSIS")
	fmt.Println(strings.Repeat("=", 80) + "\n")

	fmt.Printf("Successfully loaded %d homicide records\n\n", results.TotalRecords)

	// Question 1
	fmt.Println("Question 1: What is the Case Closure Rate by Year, and is it Improving?")
	fmt.Println("Why This Matters: Police department performance and resource allocation efficiency")
	fmt.Println(strings.Repeat("-", 80))
	fmt.Println("\nCase Closure Rates by Year (2022-2024):")
	fmt.Println(strings.Repeat("-", 80))
	fmt.Println("Year  | Total Cases | Closed | Open  | Closure Rate")
	fmt.Println(strings.Repeat("-", 80))

	for _, rate := range results.ClosureRates {
		fmt.Printf("%d | %11d | %6d | %5d | %d%%\n",
			rate.Year, rate.TotalCases, rate.ClosedCases, rate.OpenCases, rate.ClosureRatePercent)
	}

	fmt.Println("\n" + strings.Repeat("-", 80))
	fmt.Println("Key Findings:")

	if len(results.ClosureRates) >= 2 {
		first := results.ClosureRates[0]
		last := results.ClosureRates[len(results.ClosureRates)-1]
		change := last.ClosureRatePercent - first.ClosureRatePercent

		fmt.Printf("• Year %d Closure Rate: %d%%\n", first.Year, first.ClosureRatePercent)
		fmt.Printf("• Year %d Closure Rate: %d%%\n", last.Year, last.ClosureRatePercent)

		if change > 0 {
			fmt.Printf("• IMPROVEMENT: +%d%% closure rate increase\n", change)
		} else if change < 0 {
			fmt.Printf("• DECLINE: %d%% closure rate decrease\n", change)
		} else {
			fmt.Println("• No change in closure rate")
		}
	}

	fmt.Println("\n" + strings.Repeat("-", 80) + "\n")

	// Question 2
	fmt.Println("Question 2: Which Age Groups Are Most at Risk, Particularly Children & Youth?")
	fmt.Println("Why This Matters: Identifying vulnerable populations enables targeted prevention programs")
	fmt.Println(strings.Repeat("-", 80))
	fmt.Println("\nVictim Distribution by Age Group:")
	fmt.Println(strings.Repeat("-", 80))

	for _, stat := range results.AgeGroupStats {
		bar := strings.Repeat("█", stat.PercentageOfTotal/2)
		fmt.Printf("%-25s: %3d victims (%3d%%) %s\n", stat.AgeGroup, stat.Count, stat.PercentageOfTotal, bar)
	}

	fmt.Println("\n" + strings.Repeat("-", 80))
	fmt.Println("Critical Vulnerability Analysis:")

	fmt.Printf("• Children (0-12): %d homicides\n", results.YouthStats.Children)
	fmt.Printf("• Teens (13-18): %d homicides\n", results.YouthStats.Teens)
	fmt.Printf("• Combined Youth Total: %d homicides (%d%% of all homicides)\n",
		results.YouthStats.TotalYouth, results.YouthStats.YouthPercentage)

	if results.YouthStats.Children > 0 {
		fmt.Printf("• ALERT: %d children under 13 killed - critical child welfare concern\n", results.YouthStats.Children)
	}

	if results.YouthStats.Teens > 0 {
		fmt.Printf("• URGENT: %d teenagers killed - intervention programs needed\n", results.YouthStats.Teens)
	}

	fmt.Println("\n• Top 5 Most Common Victim Ages:")
	for _, ageStat := range results.TopAges {
		fmt.Printf("  Age %d: %d victims\n", ageStat.Age, ageStat.Count)
	}

	fmt.Println("\n" + strings.Repeat("=", 80) + "\n")
}

func outputCSV(results AnalysisResults, records []HomicideRecord) {
	// Create output directory
	os.MkdirAll("/app/output", 0755)

	file, err := os.Create("/app/output/homicide_analysis.csv")
	if err != nil {
		fmt.Printf("Error creating CSV file: %v\n", err)
		return
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Header
	writer.Write([]string{fmt.Sprintf("Baltimore Homicide Analysis - Generated on %s", time.Now().Format("2006-01-02"))})
	writer.Write([]string{})

	// Summary
	writer.Write([]string{"SUMMARY"})
	writer.Write([]string{"Total Records", fmt.Sprintf("%d", results.TotalRecords)})
	writer.Write([]string{})

	// Closure rates
	writer.Write([]string{"CASE CLOSURE RATES BY YEAR"})
	writer.Write([]string{"Year", "Total Cases", "Closed Cases", "Open Cases", "Closure Rate (%)"})
	for _, rate := range results.ClosureRates {
		writer.Write([]string{
			fmt.Sprintf("%d", rate.Year),
			fmt.Sprintf("%d", rate.TotalCases),
			fmt.Sprintf("%d", rate.ClosedCases),
			fmt.Sprintf("%d", rate.OpenCases),
			fmt.Sprintf("%d", rate.ClosureRatePercent),
		})
	}
	writer.Write([]string{})

	// Age groups
	writer.Write([]string{"VICTIM DISTRIBUTION BY AGE GROUP"})
	writer.Write([]string{"Age Group", "Count", "Percentage (%)"})
	for _, stat := range results.AgeGroupStats {
		writer.Write([]string{stat.AgeGroup, fmt.Sprintf("%d", stat.Count), fmt.Sprintf("%d", stat.PercentageOfTotal)})
	}
	writer.Write([]string{})

	// Youth statistics
	writer.Write([]string{"YOUTH VIOLENCE STATISTICS"})
	writer.Write([]string{"Category", "Count"})
	writer.Write([]string{"Children (0-12)", fmt.Sprintf("%d", results.YouthStats.Children)})
	writer.Write([]string{"Teens (13-18)", fmt.Sprintf("%d", results.YouthStats.Teens)})
	writer.Write([]string{"Total Youth", fmt.Sprintf("%d", results.YouthStats.TotalYouth)})
	writer.Write([]string{"Youth Percentage", fmt.Sprintf("%d%%", results.YouthStats.YouthPercentage)})
	writer.Write([]string{})

	// Top ages
	writer.Write([]string{"TOP 5 VICTIM AGES"})
	writer.Write([]string{"Age", "Count"})
	for _, ageStat := range results.TopAges {
		writer.Write([]string{fmt.Sprintf("%d", ageStat.Age), fmt.Sprintf("%d", ageStat.Count)})
	}
	writer.Write([]string{})

	// Individual records
	writer.Write([]string{"INDIVIDUAL HOMICIDE RECORDS"})
	writer.Write([]string{"Date", "Name", "Age", "Address", "Year", "Case Closed"})

	// Sort records by year and date
	sortedRecords := make([]HomicideRecord, len(records))
	copy(sortedRecords, records)
	sort.Slice(sortedRecords, func(i, j int) bool {
		if sortedRecords[i].Year != sortedRecords[j].Year {
			return sortedRecords[i].Year < sortedRecords[j].Year
		}
		return sortedRecords[i].Date < sortedRecords[j].Date
	})

	for _, record := range sortedRecords {
		closedStr := "No"
		if record.CaseClosed {
			closedStr = "Yes"
		}
		safeName := strings.ReplaceAll(record.Name, ",", ";")
		safeAddress := strings.ReplaceAll(record.Address, ",", ";")

		writer.Write([]string{
			record.Date,
			safeName,
			fmt.Sprintf("%d", record.Age),
			safeAddress,
			fmt.Sprintf("%d", record.Year),
			closedStr,
		})
	}

	fmt.Printf("CSV file written successfully: %d records\n", results.TotalRecords)
}

func outputJSON(results AnalysisResults, records []HomicideRecord) {
	// Create output directory
	os.MkdirAll("/app/output", 0755)

	// Sort records by year and date
	sortedRecords := make([]HomicideRecord, len(records))
	copy(sortedRecords, records)
	sort.Slice(sortedRecords, func(i, j int) bool {
		if sortedRecords[i].Year != sortedRecords[j].Year {
			return sortedRecords[i].Year < sortedRecords[j].Year
		}
		return sortedRecords[i].Date < sortedRecords[j].Date
	})

	output := JSONOutput{
		Metadata: Metadata{
			GeneratedDate: time.Now().Format("2006-01-02"),
			TotalRecords:  results.TotalRecords,
			Source:        "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
		},
		ClosureRates:       results.ClosureRates,
		AgeGroupStatistics: results.AgeGroupStats,
		YouthStatistics:    results.YouthStats,
		TopVictimAges:      results.TopAges,
		HomicideRecords:    sortedRecords,
	}

	file, err := os.Create("/app/output/homicide_analysis.json")
	if err != nil {
		fmt.Printf("Error creating JSON file: %v\n", err)
		return
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")

	if err := encoder.Encode(output); err != nil {
		fmt.Printf("Error encoding JSON: %v\n", err)
		return
	}

	fmt.Printf("JSON file written successfully: %d records\n", results.TotalRecords)
}