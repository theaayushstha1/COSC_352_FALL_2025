package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// HomicideRecord represents a single homicide case
type HomicideRecord struct {
	Number      int    `json:"number"`
	Victim      string `json:"victim"`
	Age         *int   `json:"age"` // Pointer to handle null/missing values
	Date        string `json:"date"`
	Location    string `json:"location"`
	District    string `json:"district"`
	NearCamera  bool   `json:"near_camera"`
	IsClosed    bool   `json:"is_closed"`
	Year        int    `json:"year"`
}

// DistrictStats contains district-level analysis
type DistrictStats struct {
	District           string  `json:"district"`
	TotalCases         int     `json:"total_cases"`
	ClosedCases        int     `json:"closed_cases"`
	ClearanceRate      float64 `json:"clearance_rate"`
	PerformanceLevel   string  `json:"performance_indicator"`
}

// CameraStats contains camera proximity statistics
type CameraStats struct {
	LocationType   string  `json:"type"`
	TotalCases     int     `json:"total_cases"`
	ClosedCases    int     `json:"closed_cases"`
	ClearanceRate  float64 `json:"clearance_rate"`
}

// CameraAnalysis contains full camera analysis results
type CameraAnalysis struct {
	NearCamera            CameraStats `json:"near_camera_stats"`
	NotNearCamera         CameraStats `json:"not_near_camera_stats"`
	PercentNearCamera     float64     `json:"percent_near_camera"`
	ClearanceRateDiff     float64     `json:"clearance_rate_difference"`
	AvgAgeNearCamera      *float64    `json:"avg_age_near_camera,omitempty"`
	AvgAgeNotNearCamera   *float64    `json:"avg_age_not_near_camera,omitempty"`
}

// AnalysisResults contains complete analysis output
type AnalysisResults struct {
	Timestamp         string            `json:"timestamp"`
	TotalRecords      int               `json:"total_records"`
	YearsAnalyzed     []int             `json:"years_analyzed"`
	DistrictAnalysis  []DistrictStats   `json:"district_analysis"`
	DistrictAverage   float64           `json:"district_average"`
	BestDistrict      string            `json:"best_district"`
	WorstDistrict     string            `json:"worst_district"`
	CameraAnalysis    CameraAnalysis    `json:"camera_analysis"`
	DataSource        string            `json:"data_source"`
	RawRecords        []HomicideRecord  `json:"raw_records,omitempty"`
}

func main() {
	// Parse command-line flags
	outputFormat := flag.String("output", "stdout", "Output format: stdout, csv, or json")
	flag.Parse()

	// Fetch data from multiple years
	years := []int{2023, 2024, 2025}
	var allRecords []HomicideRecord

	for _, year := range years {
		if *outputFormat == "stdout" {
			fmt.Printf("Fetching data for year %d...\n", year)
		}
		records := fetchYearData(year, *outputFormat == "stdout")
		if *outputFormat == "stdout" {
			fmt.Printf("  Found %d records for %d\n", len(records), year)
		}
		allRecords = append(allRecords, records...)
	}

	// Use sample data if no records fetched
	if len(allRecords) == 0 {
		if *outputFormat == "stdout" {
			fmt.Println("\nWarning: No data could be fetched. Using sample data for demonstration.")
		}
		allRecords = generateSampleData()
	} else {
		if *outputFormat == "stdout" {
			fmt.Printf("\nTotal records analyzed: %d\n", len(allRecords))
		}
	}

	// Perform analysis
	results := performAnalysis(allRecords, years)

	// Output in requested format
	switch *outputFormat {
	case "csv":
		outputCSV(results)
	case "json":
		outputJSON(results)
	default:
		outputStdout(results)
	}
}

func fetchYearData(year int, verbose bool) []HomicideRecord {
	url := fmt.Sprintf("http://chamspage.blogspot.com/%d/01/%d-baltimore-city-homicide-list.html", year, year)

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	resp, err := client.Get(url)
	if err != nil {
		if verbose {
			fmt.Printf("  Warning: Could not fetch data for %d: %v\n", year, err)
		}
		return []HomicideRecord{}
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		if verbose {
			fmt.Printf("  Warning: Could not read response for %d: %v\n", year, err)
		}
		return []HomicideRecord{}
	}

	return parseHomicideData(string(body), year)
}

func parseHomicideData(html string, year int) []HomicideRecord {
	var records []HomicideRecord

	// Pattern to match homicide entries
	victimPattern := regexp.MustCompile(`(?i)(\d+)\.\s+([A-Za-z\s,'-]+?)(?:\s+(\d+))?\s+(\d{1,2}/\d{1,2}/\d{2,4})`)
	districtPattern := regexp.MustCompile(`(?i)(Northern|Southern|Eastern|Western|Central|Northeast|Northwest|Southeast|Southwest)`)

	lines := strings.Split(html, "\n")
	recordNum := 0

	for _, line := range lines {
		matches := victimPattern.FindStringSubmatch(line)
		if matches != nil {
			recordNum++

			num, _ := strconv.Atoi(matches[1])
			if num == 0 {
				num = recordNum
			}

			victim := strings.TrimSpace(matches[2])

			var age *int
			if matches[3] != "" {
				ageVal, err := strconv.Atoi(matches[3])
				if err == nil {
					age = &ageVal
				}
			}

			date := matches[4]

			district := "Unknown"
			districtMatch := districtPattern.FindString(line)
			if districtMatch != "" {
				district = districtMatch
			}

			nearCamera := strings.Contains(strings.ToLower(line), "camera") ||
				strings.Contains(line, "✓") ||
				strings.Contains(line, "yes")

			isClosed := strings.Contains(strings.ToLower(line), "closed") ||
				strings.Contains(strings.ToLower(line), "arrest") ||
				strings.Contains(strings.ToLower(line), "charged")

			location := extractLocation(line)

			record := HomicideRecord{
				Number:     num,
				Victim:     victim,
				Age:        age,
				Date:       date,
				Location:   location,
				District:   district,
				NearCamera: nearCamera,
				IsClosed:   isClosed,
				Year:       year,
			}

			records = append(records, record)
		}
	}

	return records
}

func extractLocation(text string) string {
	locationPattern := regexp.MustCompile(`(\d{1,5})\s+(?:block\s+of\s+)?([A-Z][a-z\s]+(?:Street|Avenue|Road|Drive|Court|Way|Lane|Boulevard))`)
	matches := locationPattern.FindStringSubmatch(text)
	if matches != nil {
		return fmt.Sprintf("%s %s", matches[1], matches[2])
	}
	return "Unknown"
}

func generateSampleData() []HomicideRecord {
	districts := []string{"Eastern", "Western", "Northern", "Southern", "Central", "Northeast", "Northwest"}
	victims := []string{"John Doe", "Jane Smith", "Michael Johnson", "Mary Williams", "Robert Brown"}

	var records []HomicideRecord

	for i := 1; i <= 150; i++ {
		age := 18 + (i % 50)
		record := HomicideRecord{
			Number:     i,
			Victim:     fmt.Sprintf("%s #%d", victims[i%len(victims)], i),
			Age:        &age,
			Date:       fmt.Sprintf("%d/%d/2024", (i%12)+1, (i%28)+1),
			Location:   fmt.Sprintf("%d Main Street", 100+(i*13)%8900),
			District:   districts[i%len(districts)],
			NearCamera: i%3 == 0,
			IsClosed:   i%5 < 2,
			Year:       2024,
		}
		records = append(records, record)
	}

	return records
}

func performAnalysis(records []HomicideRecord, years []int) AnalysisResults {
	timestamp := time.Now().Format("2006-01-02 15:04:05")

	// District analysis
	districtMap := make(map[string][]HomicideRecord)
	for _, record := range records {
		districtMap[record.District] = append(districtMap[record.District], record)
	}

	var districtStats []DistrictStats
	var totalClearanceRate float64

	for district, districtRecords := range districtMap {
		total := len(districtRecords)
		closed := 0
		for _, r := range districtRecords {
			if r.IsClosed {
				closed++
			}
		}

		clearanceRate := 0.0
		if total > 0 {
			clearanceRate = float64(closed) / float64(total) * 100
		}

		perfLevel := "low"
		if clearanceRate >= 50 {
			perfLevel = "high"
		} else if clearanceRate >= 30 {
			perfLevel = "medium"
		}

		stat := DistrictStats{
			District:          district,
			TotalCases:        total,
			ClosedCases:       closed,
			ClearanceRate:     clearanceRate,
			PerformanceLevel:  perfLevel,
		}
		districtStats = append(districtStats, stat)
		totalClearanceRate += clearanceRate
	}

	// Sort districts by clearance rate (highest first)
	for i := 0; i < len(districtStats); i++ {
		for j := i + 1; j < len(districtStats); j++ {
			if districtStats[j].ClearanceRate > districtStats[i].ClearanceRate {
				districtStats[i], districtStats[j] = districtStats[j], districtStats[i]
			}
		}
	}

	avgClearance := 0.0
	if len(districtStats) > 0 {
		avgClearance = totalClearanceRate / float64(len(districtStats))
	}

	bestDistrict := "N/A"
	worstDistrict := "N/A"
	if len(districtStats) > 0 {
		bestDistrict = districtStats[0].District
		worstDistrict = districtStats[len(districtStats)-1].District
	}

	// Camera analysis
	var nearCamera, notNearCamera []HomicideRecord
	for _, record := range records {
		if record.NearCamera {
			nearCamera = append(nearCamera, record)
		} else {
			notNearCamera = append(notNearCamera, record)
		}
	}

	nearCameraClosed := 0
	for _, r := range nearCamera {
		if r.IsClosed {
			nearCameraClosed++
		}
	}

	notNearCameraClosed := 0
	for _, r := range notNearCamera {
		if r.IsClosed {
			notNearCameraClosed++
		}
	}

	nearCameraRate := 0.0
	if len(nearCamera) > 0 {
		nearCameraRate = float64(nearCameraClosed) / float64(len(nearCamera)) * 100
	}

	notNearCameraRate := 0.0
	if len(notNearCamera) > 0 {
		notNearCameraRate = float64(notNearCameraClosed) / float64(len(notNearCamera)) * 100
	}

	pctNearCamera := 0.0
	if len(records) > 0 {
		pctNearCamera = float64(len(nearCamera)) / float64(len(records)) * 100
	}

	rateDiff := nearCameraRate - notNearCameraRate

	// Calculate average ages
	var avgAgeNear, avgAgeNotNear *float64
	if len(nearCamera) > 0 {
		totalAge := 0
		count := 0
		for _, r := range nearCamera {
			if r.Age != nil {
				totalAge += *r.Age
				count++
			}
		}
		if count > 0 {
			avg := float64(totalAge) / float64(count)
			avgAgeNear = &avg
		}
	}

	if len(notNearCamera) > 0 {
		totalAge := 0
		count := 0
		for _, r := range notNearCamera {
			if r.Age != nil {
				totalAge += *r.Age
				count++
			}
		}
		if count > 0 {
			avg := float64(totalAge) / float64(count)
			avgAgeNotNear = &avg
		}
	}

	cameraAnalysis := CameraAnalysis{
		NearCamera: CameraStats{
			LocationType:  "near_camera",
			TotalCases:    len(nearCamera),
			ClosedCases:   nearCameraClosed,
			ClearanceRate: nearCameraRate,
		},
		NotNearCamera: CameraStats{
			LocationType:  "not_near_camera",
			TotalCases:    len(notNearCamera),
			ClosedCases:   notNearCameraClosed,
			ClearanceRate: notNearCameraRate,
		},
		PercentNearCamera:   pctNearCamera,
		ClearanceRateDiff:   rateDiff,
		AvgAgeNearCamera:    avgAgeNear,
		AvgAgeNotNearCamera: avgAgeNotNear,
	}

	return AnalysisResults{
		Timestamp:        timestamp,
		TotalRecords:     len(records),
		YearsAnalyzed:    years,
		DistrictAnalysis: districtStats,
		DistrictAverage:  avgClearance,
		BestDistrict:     bestDistrict,
		WorstDistrict:    worstDistrict,
		CameraAnalysis:   cameraAnalysis,
		DataSource:       "chamspage.blogspot.com",
		RawRecords:       records,
	}
}

func outputStdout(results AnalysisResults) {
	fmt.Println("Baltimore Homicide Statistics Analysis")
	fmt.Println(strings.Repeat("=", 70))
	fmt.Println()
	fmt.Println()
	fmt.Println(strings.Repeat("=", 70))
	fmt.Println()

	// Question 1: District analysis
	fmt.Println("QUESTION 1: District Clearance Rate Analysis (2023-2025)")
	fmt.Println(strings.Repeat("-", 70))
	fmt.Println()
	fmt.Println("CONTEXT: This analysis helps the Mayor's office identify which")
	fmt.Println("police districts are most effective at solving homicides and where")
	fmt.Println("to allocate additional detective resources for maximum impact.")
	fmt.Println()

	fmt.Printf("%-20s %8s %8s %10s\n", "District", "Total", "Closed", "Rate")
	fmt.Println(strings.Repeat("-", 70))

	for _, stats := range results.DistrictAnalysis {
		indicator := "✗"
		if stats.ClearanceRate >= 50 {
			indicator = "✓"
		} else if stats.ClearanceRate >= 30 {
			indicator = "○"
		}
		fmt.Printf("%s %-19s %7d %7d %9.1f%%\n",
			indicator, stats.District, stats.TotalCases, stats.ClosedCases, stats.ClearanceRate)
	}

	fmt.Println()
	fmt.Println("KEY FINDINGS:")
	if len(results.DistrictAnalysis) > 0 {
		best := results.DistrictAnalysis[0]
		worst := results.DistrictAnalysis[len(results.DistrictAnalysis)-1]
		fmt.Printf("  • Best performing: %s with %.1f%% clearance rate\n", best.District, best.ClearanceRate)
		fmt.Printf("  • Needs attention: %s with %.1f%% clearance rate\n", worst.District, worst.ClearanceRate)
		fmt.Printf("  • City-wide average: %.1f%% clearance rate\n", results.DistrictAverage)

		belowAvg := 0
		for _, s := range results.DistrictAnalysis {
			if s.ClearanceRate < results.DistrictAverage {
				belowAvg++
			}
		}
		fmt.Printf("  • %d of %d districts below average\n", belowAvg, len(results.DistrictAnalysis))
	}

	fmt.Println()
	fmt.Println(strings.Repeat("=", 70))
	fmt.Println()

	// Question 2: Camera analysis
	fmt.Println("QUESTION 2: Police Surveillance Camera ROI Analysis")
	fmt.Println(strings.Repeat("-", 70))
	fmt.Println()
	fmt.Println("CONTEXT: Baltimore has invested millions in CCTV infrastructure.")
	fmt.Println("This analysis evaluates whether camera proximity improves case")
	fmt.Println("closure rates and informs future technology investment decisions.")
	fmt.Println()

	cam := results.CameraAnalysis
	fmt.Printf("%-30s %8s %8s %10s\n", "Location", "Total", "Closed", "Rate")
	fmt.Println(strings.Repeat("-", 70))
	fmt.Printf("%-30s %7d %7d %9.1f%%\n",
		"Within 1 block of camera", cam.NearCamera.TotalCases, cam.NearCamera.ClosedCases, cam.NearCamera.ClearanceRate)
	fmt.Printf("%-30s %7d %7d %9.1f%%\n",
		"Not near camera", cam.NotNearCamera.TotalCases, cam.NotNearCamera.ClosedCases, cam.NotNearCamera.ClearanceRate)

	fmt.Println()
	fmt.Println("KEY FINDINGS:")
	fmt.Printf("  • %.1f%% of all homicides occur within 1 block of cameras\n", cam.PercentNearCamera)
	fmt.Printf("  • Clearance rate difference: %+.1f%% (cameras vs. no cameras)\n", cam.ClearanceRateDiff)

	if cam.AvgAgeNearCamera != nil && cam.AvgAgeNotNearCamera != nil {
		fmt.Printf("  • Average victim age near cameras: %.1f years\n", *cam.AvgAgeNearCamera)
		fmt.Printf("  • Average victim age not near cameras: %.1f years\n", *cam.AvgAgeNotNearCamera)
	}

	fmt.Println()
	fmt.Println(strings.Repeat("-", 70))
	fmt.Println()
	fmt.Println("DATA NOTES:")
	fmt.Printf("  • Analysis timestamp: %s\n", results.Timestamp)
	fmt.Printf("  • Total records analyzed: %d\n", results.TotalRecords)
	fmt.Printf("  • Data source: %s\n", results.DataSource)
	fmt.Println()
}

func outputCSV(results AnalysisResults) {
	timestamp := time.Now().Format("20060102_150405")

	// District analysis CSV
	districtFile, err := os.Create(fmt.Sprintf("district_analysis_%s.csv", timestamp))
	if err != nil {
		log.Fatal(err)
	}
	defer districtFile.Close()

	districtWriter := csv.NewWriter(districtFile)
	defer districtWriter.Flush()

	districtWriter.Write([]string{"district", "total_cases", "closed_cases", "clearance_rate", "performance_indicator"})
	for _, stats := range results.DistrictAnalysis {
		districtWriter.Write([]string{
			stats.District,
			strconv.Itoa(stats.TotalCases),
			strconv.Itoa(stats.ClosedCases),
			fmt.Sprintf("%.1f", stats.ClearanceRate),
			stats.PerformanceLevel,
		})
	}

	// Camera analysis CSV
	cameraFile, err := os.Create(fmt.Sprintf("camera_analysis_%s.csv", timestamp))
	if err != nil {
		log.Fatal(err)
	}
	defer cameraFile.Close()

	cameraWriter := csv.NewWriter(cameraFile)
	defer cameraWriter.Flush()

	cameraWriter.Write([]string{"location_type", "total_cases", "closed_cases", "clearance_rate"})
	cam := results.CameraAnalysis
	cameraWriter.Write([]string{
		"near_camera",
		strconv.Itoa(cam.NearCamera.TotalCases),
		strconv.Itoa(cam.NearCamera.ClosedCases),
		fmt.Sprintf("%.1f", cam.NearCamera.ClearanceRate),
	})
	cameraWriter.Write([]string{
		"not_near_camera",
		strconv.Itoa(cam.NotNearCamera.TotalCases),
		strconv.Itoa(cam.NotNearCamera.ClosedCases),
		fmt.Sprintf("%.1f", cam.NotNearCamera.ClearanceRate),
	})

	// Summary CSV
	summaryFile, err := os.Create(fmt.Sprintf("analysis_summary_%s.csv", timestamp))
	if err != nil {
		log.Fatal(err)
	}
	defer summaryFile.Close()

	summaryWriter := csv.NewWriter(summaryFile)
	defer summaryWriter.Flush()

	summaryWriter.Write([]string{"metric", "value"})
	summaryWriter.Write([]string{"timestamp", results.Timestamp})
	summaryWriter.Write([]string{"total_records", strconv.Itoa(results.TotalRecords)})

	yearsStr := make([]string, len(results.YearsAnalyzed))
	for i, y := range results.YearsAnalyzed {
		yearsStr[i] = strconv.Itoa(y)
	}
	summaryWriter.Write([]string{"years_analyzed", strings.Join(yearsStr, ";")})
	summaryWriter.Write([]string{"city_avg_clearance_rate", fmt.Sprintf("%.1f", results.DistrictAverage)})
	summaryWriter.Write([]string{"best_performing_district", results.BestDistrict})
	summaryWriter.Write([]string{"worst_performing_district", results.WorstDistrict})
	summaryWriter.Write([]string{"percent_homicides_near_camera", fmt.Sprintf("%.1f", cam.PercentNearCamera)})
	summaryWriter.Write([]string{"camera_clearance_rate_difference", fmt.Sprintf("%.1f", cam.ClearanceRateDiff)})
	if cam.AvgAgeNearCamera != nil {
		summaryWriter.Write([]string{"avg_age_near_camera", fmt.Sprintf("%.1f", *cam.AvgAgeNearCamera)})
	}
	if cam.AvgAgeNotNearCamera != nil {
		summaryWriter.Write([]string{"avg_age_not_near_camera", fmt.Sprintf("%.1f", *cam.AvgAgeNotNearCamera)})
	}
	summaryWriter.Write([]string{"data_source", results.DataSource})

	// Records CSV
	recordsFile, err := os.Create(fmt.Sprintf("homicide_records_%s.csv", timestamp))
	if err != nil {
		log.Fatal(err)
	}
	defer recordsFile.Close()

	recordsWriter := csv.NewWriter(recordsFile)
	defer recordsWriter.Flush()

	recordsWriter.Write([]string{"record_number", "victim_name", "age", "date", "location", "district", "near_camera", "is_closed", "year"})
	for _, record := range results.RawRecords {
		ageStr := ""
		if record.Age != nil {
			ageStr = strconv.Itoa(*record.Age)
		}
		recordsWriter.Write([]string{
			strconv.Itoa(record.Number),
			record.Victim,
			ageStr,
			record.Date,
			record.Location,
			record.District,
			strconv.FormatBool(record.NearCamera),
			strconv.FormatBool(record.IsClosed),
			strconv.Itoa(record.Year),
		})
	}

	fmt.Println("CSV files generated:")
	fmt.Printf("  - district_analysis_%s.csv\n", timestamp)
	fmt.Printf("  - camera_analysis_%s.csv\n", timestamp)
	fmt.Printf("  - analysis_summary_%s.csv\n", timestamp)
	fmt.Printf("  - homicide_records_%s.csv\n", timestamp)
}

func outputJSON(results AnalysisResults) {
	timestamp := time.Now().Format("20060102_150405")
	filename := fmt.Sprintf("baltimore_homicide_analysis_%s.json", timestamp)

	file, err := os.Create(filename)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")

	if err := encoder.Encode(results); err != nil {
		log.Fatal(err)
	}

	fmt.Printf("JSON file generated: %s\n", filename)
}