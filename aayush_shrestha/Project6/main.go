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

// Homicide represents a single homicide record
type Homicide struct {
	Number        string `json:"number"`
	DateDied      string `json:"date_died"`
	Name          string `json:"name"`
	Age           string `json:"age"`
	Address       string `json:"address"`
	CameraPresent string `json:"camera_present"`
	CaseClosed    string `json:"case_status"`
}

// LocationHotspot represents location analysis results
type LocationHotspot struct {
	Location       string  `json:"location"`
	TotalCases     int     `json:"total_cases"`
	OpenCases      int     `json:"open_cases"`
	ClosedCases    int     `json:"closed_cases"`
	ClosureRate    float64 `json:"closure_rate"`
	CamerasPresent int     `json:"cameras_present"`
	AvgVictimAge   float64 `json:"avg_victim_age"`
}

// AgeGroupAnalysis represents age group analysis results
type AgeGroupAnalysis struct {
	AgeGroup       string  `json:"age_group"`
	TotalCases     int     `json:"total_cases"`
	ClosedCases    int     `json:"closed_cases"`
	OpenCases      int     `json:"open_cases"`
	ClosureRate    float64 `json:"closure_rate"`
	CamerasPresent int     `json:"cameras_present"`
}

// AnalysisResults contains all analysis data
type AnalysisResults struct {
	Metadata struct {
		TotalHomicides     int     `json:"total_homicides"`
		OverallClosureRate float64 `json:"overall_closure_rate"`
		CriticalZonesCount int     `json:"critical_zones_count"`
	} `json:"analysis_metadata"`
	LocationHotspots   []LocationHotspot  `json:"location_hotspots"`
	AgeGroupAnalysis   []AgeGroupAnalysis `json:"age_group_analysis"`
	RawHomicideData    []Homicide         `json:"raw_homicide_data"`
}

func main() {
	outputFormat := "stdout"
	if len(os.Args) > 1 {
		outputFormat = os.Args[1]
	}

	printHeader()

	// Fetch data with goroutine for async operation
	homicideChan := make(chan []Homicide, 1)
	go func() {
		homicideChan <- fetchRealData()
	}()

	// Wait for data with timeout
	var homicides []Homicide
	select {
	case homicides = <-homicideChan:
	case <-time.After(10 * time.Second):
		fmt.Println("⚠ Data fetch timeout. Using sample data.")
		homicides = getSampleData()
	}

	if len(homicides) == 0 {
		fmt.Println("WARNING: Could not fetch live data. Using sample data for demonstration.")
		fmt.Println()
		homicides = getSampleData()
	} else {
		fmt.Printf("✓ Successfully loaded %d homicide records\n\n", len(homicides))
	}

	processData(homicides, outputFormat)
}

func printHeader() {
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println("BALTIMORE CITY HOMICIDE DATA ANALYSIS")
	fmt.Println("Mayor's Office Strategic Crime Prevention Initiative")
	fmt.Println("Data Source: chamspage.blogspot.com")
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println()
}

func processData(homicides []Homicide, outputFormat string) {
	switch strings.ToLower(outputFormat) {
	case "csv":
		fmt.Println("Generating CSV output...")
		results := performAnalysis(homicides)
		if err := writeCSV(results); err != nil {
			fmt.Printf("Error writing CSV: %v\n", err)
			return
		}
		fmt.Println("✓ CSV file generated: /output/baltimore_homicide_analysis.csv")
	case "json":
		fmt.Println("Generating JSON output...")
		results := performAnalysis(homicides)
		if err := writeJSON(results); err != nil {
			fmt.Printf("Error writing JSON: %v\n", err)
			return
		}
		fmt.Println("✓ JSON file generated: /output/baltimore_homicide_analysis.json")
	default:
		analyzeAndPrint(homicides)
	}
}

func performAnalysis(homicides []Homicide) AnalysisResults {
	results := AnalysisResults{}
	results.RawHomicideData = homicides

	// Location analysis
	locationMap := make(map[string][]Homicide)
	for _, h := range homicides {
		normalized := normalizeAddress(h.Address)
		locationMap[normalized] = append(locationMap[normalized], h)
	}

	// Build location hotspots
	for location, cases := range locationMap {
		totalCases := len(cases)
		closedCases := countClosed(cases)
		openCases := totalCases - closedCases
		closureRate := 0.0
		if totalCases > 0 {
			closureRate = float64(closedCases) / float64(totalCases) * 100
		}
		camerasPresent := countCameras(cases)
		avgAge := calculateAvgAge(cases)

		hotspot := LocationHotspot{
			Location:       location,
			TotalCases:     totalCases,
			OpenCases:      openCases,
			ClosedCases:    closedCases,
			ClosureRate:    closureRate,
			CamerasPresent: camerasPresent,
			AvgVictimAge:   avgAge,
		}
		results.LocationHotspots = append(results.LocationHotspots, hotspot)
	}

	// Sort by total cases descending
	sort.Slice(results.LocationHotspots, func(i, j int) bool {
		return results.LocationHotspots[i].TotalCases > results.LocationHotspots[j].TotalCases
	})

	// Age group analysis
	ageGroups := map[string][2]int{
		"Minors (Under 18)":    {0, 17},
		"Young Adults (18-25)": {18, 25},
		"Adults (26-40)":       {26, 40},
		"Middle Age (41-60)":   {41, 60},
		"Seniors (61+)":        {61, 150},
	}

	for groupName, ageRange := range ageGroups {
		groupCases := filterByAgeRange(homicides, ageRange[0], ageRange[1])
		total := len(groupCases)
		closed := countClosed(groupCases)
		open := total - closed
		closureRate := 0.0
		if total > 0 {
			closureRate = float64(closed) / float64(total) * 100
		}
		cameras := countCameras(groupCases)

		ageAnalysis := AgeGroupAnalysis{
			AgeGroup:       groupName,
			TotalCases:     total,
			ClosedCases:    closed,
			OpenCases:      open,
			ClosureRate:    closureRate,
			CamerasPresent: cameras,
		}
		results.AgeGroupAnalysis = append(results.AgeGroupAnalysis, ageAnalysis)
	}

	// Sort by total cases descending
	sort.Slice(results.AgeGroupAnalysis, func(i, j int) bool {
		return results.AgeGroupAnalysis[i].TotalCases > results.AgeGroupAnalysis[j].TotalCases
	})

	// Calculate metadata
	results.Metadata.TotalHomicides = len(homicides)
	results.Metadata.OverallClosureRate = 0.0
	if len(homicides) > 0 {
		results.Metadata.OverallClosureRate = float64(countClosed(homicides)) / float64(len(homicides)) * 100
	}
	results.Metadata.CriticalZonesCount = countCriticalZones(results.LocationHotspots)

	return results
}

func writeCSV(results AnalysisResults) error {
	file, err := os.Create("/output/baltimore_homicide_analysis.csv")
	if err != nil {
		return err
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Metadata
	writer.Write([]string{"BALTIMORE CITY HOMICIDE DATA ANALYSIS"})
	writer.Write([]string{"Total Homicides", strconv.Itoa(results.Metadata.TotalHomicides)})
	writer.Write([]string{"Overall Closure Rate", fmt.Sprintf("%.2f%%", results.Metadata.OverallClosureRate)})
	writer.Write([]string{"Critical Zones Count", strconv.Itoa(results.Metadata.CriticalZonesCount)})
	writer.Write([]string{})

	// Location Hotspots
	writer.Write([]string{"LOCATION HOTSPOTS ANALYSIS"})
	writer.Write([]string{"Location", "Total Cases", "Open Cases", "Closed Cases", "Closure Rate (%)", "Cameras Present", "Avg Victim Age"})
	for _, hotspot := range results.LocationHotspots {
		writer.Write([]string{
			hotspot.Location,
			strconv.Itoa(hotspot.TotalCases),
			strconv.Itoa(hotspot.OpenCases),
			strconv.Itoa(hotspot.ClosedCases),
			fmt.Sprintf("%.2f", hotspot.ClosureRate),
			strconv.Itoa(hotspot.CamerasPresent),
			fmt.Sprintf("%.0f", hotspot.AvgVictimAge),
		})
	}
	writer.Write([]string{})

	// Age Group Analysis
	writer.Write([]string{"AGE GROUP ANALYSIS"})
	writer.Write([]string{"Age Group", "Total Cases", "Closed Cases", "Open Cases", "Closure Rate (%)", "Cameras Present"})
	for _, group := range results.AgeGroupAnalysis {
		writer.Write([]string{
			group.AgeGroup,
			strconv.Itoa(group.TotalCases),
			strconv.Itoa(group.ClosedCases),
			strconv.Itoa(group.OpenCases),
			fmt.Sprintf("%.2f", group.ClosureRate),
			strconv.Itoa(group.CamerasPresent),
		})
	}
	writer.Write([]string{})

	// Raw Data
	writer.Write([]string{"RAW HOMICIDE DATA"})
	writer.Write([]string{"Number", "Date Died", "Name", "Age", "Address", "Camera Present", "Case Status"})
	for _, h := range results.RawHomicideData {
		writer.Write([]string{h.Number, h.DateDied, h.Name, h.Age, h.Address, h.CameraPresent, h.CaseClosed})
	}

	return nil
}

func writeJSON(results AnalysisResults) error {
	file, err := os.Create("/output/baltimore_homicide_analysis.json")
	if err != nil {
		return err
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	return encoder.Encode(results)
}

func fetchRealData() []Homicide {
	fmt.Println("Fetching live data from chamspage.blogspot.com...")
	
	client := &http.Client{
		Timeout: 10 * time.Second,
	}
	
	resp, err := client.Get("http://chamspage.blogspot.com")
	if err != nil {
		fmt.Printf("✗ Error: %v\n\n", err)
		return []Homicide{}
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Printf("✗ Error reading response: %v\n\n", err)
		return []Homicide{}
	}

	// Parse HTML table (simplified parsing)
	html := string(body)
	lines := strings.Split(html, "\n")
	
	var homicides []Homicide
	inTable := false
	
	for _, line := range lines {
		if strings.Contains(line, "<table") {
			inTable = true
		} else if strings.Contains(line, "</table>") {
			inTable = false
		}
		
		if inTable && strings.Contains(line, "<tr>") {
			// Extract table cells
			re := regexp.MustCompile(`<td[^>]*>(.*?)</td>`)
			matches := re.FindAllStringSubmatch(line, -1)
			
			if len(matches) >= 9 {
				cells := make([]string, len(matches))
				for i, match := range matches {
					cells[i] = strings.TrimSpace(stripHTML(match[1]))
				}
				
				if matched, _ := regexp.MatchString(`^\d+$`, cells[0]); matched {
					homicide := Homicide{
						Number:        cells[0],
						DateDied:      cells[1],
						Name:          cells[2],
						Age:           cells[3],
						Address:       cells[4],
						CameraPresent: cells[7],
						CaseClosed:    cells[8],
					}
					homicides = append(homicides, homicide)
				}
			}
		}
	}

	if len(homicides) > 0 {
		fmt.Printf("✓ Retrieved %d records\n\n", len(homicides))
	}
	
	return homicides
}

func getSampleData() []Homicide {
	return []Homicide{
		{"1", "01/05/25", "John Smith", "17", "1200 block N Broadway", "camera at intersection", "Open"},
		{"2", "01/12/25", "Maria Garcia", "34", "1200 block N Broadway", "None", "Closed"},
		{"3", "01/18/25", "James Johnson", "22", "2500 block E Monument St", "camera at intersection", "Closed"},
		{"4", "02/03/25", "Robert Williams", "45", "2500 block E Monument St", "None", "Open"},
		{"5", "02/14/25", "Michael Brown", "28", "800 block W Baltimore St", "camera at intersection", "Closed"},
		{"6", "03/07/25", "David Jones", "19", "800 block W Baltimore St", "None", "Open"},
		{"7", "03/22/25", "Christopher Davis", "56", "1500 block W North Ave", "camera at intersection", "Closed"},
		{"8", "04/10/25", "Daniel Miller", "31", "1500 block W North Ave", "None", "Open"},
		{"9", "05/15/25", "Matthew Wilson", "42", "3300 block Greenmount Ave", "camera at intersection", "Closed"},
		{"10", "06/20/25", "Anthony Moore", "25", "3300 block Greenmount Ave", "camera at intersection", "Closed"},
		{"11", "07/04/25", "Donald Taylor", "63", "900 block N Carey St", "None", "Open"},
		{"12", "07/18/25", "Mark Anderson", "29", "900 block N Carey St", "camera at intersection", "Closed"},
		{"13", "08/09/25", "Steven Thomas", "38", "1700 block E North Ave", "camera at intersection", "Closed"},
		{"14", "08/22/25", "Paul Jackson", "21", "1700 block E North Ave", "None", "Open"},
		{"15", "09/12/25", "Andrew White", "47", "2100 block W Pratt St", "camera at intersection", "Closed"},
		{"16", "09/25/25", "Joshua Harris", "16", "2100 block W Pratt St", "None", "Open"},
		{"17", "10/08/25", "Kenneth Martin", "52", "4200 block Park Heights Ave", "camera at intersection", "Closed"},
		{"18", "10/15/25", "Kevin Thompson", "26", "4200 block Park Heights Ave", "None", "Open"},
		{"19", "11/03/25", "Brian Garcia", "33", "800 block N Gay St", "camera at intersection", "Closed"},
		{"20", "11/20/25", "George Martinez", "71", "1400 block W Fayette St", "None", "Open"},
		{"21", "12/05/25", "Edward Robinson", "24", "2200 block Druid Hill Ave", "camera at intersection", "Closed"},
		{"22", "12/18/25", "Ronald Clark", "39", "1100 block E Monument St", "None", "Closed"},
		{"23", "01/10/25", "Timothy Rodriguez", "15", "3400 block W Baltimore St", "camera at intersection", "Open"},
		{"24", "02/20/25", "Jason Lewis", "58", "1800 block N Charles St", "None", "Closed"},
		{"25", "03/15/25", "Jeffrey Lee", "27", "1200 block N Broadway", "camera at intersection", "Open"},
	}
}

// Helper functions
func normalizeAddress(address string) string {
	re := regexp.MustCompile(`(\d+)\s+block\s+(.+)`)
	matches := re.FindStringSubmatch(strings.ToLower(address))
	
	if len(matches) >= 3 {
		street := strings.Fields(matches[2])
		if len(street) > 3 {
			street = street[:3]
		}
		normalized := fmt.Sprintf("%s block %s", matches[1], strings.Join(street, " "))
		if len(normalized) > 35 {
			normalized = normalized[:35]
		}
		return normalized
	}
	
	fields := strings.Fields(address)
	if len(fields) > 4 {
		fields = fields[:4]
	}
	result := strings.ToLower(strings.Join(fields, " "))
	if len(result) > 35 {
		result = result[:35]
	}
	return result
}

func stripHTML(s string) string {
	re := regexp.MustCompile(`<[^>]*>`)
	return re.ReplaceAllString(s, "")
}

func countClosed(homicides []Homicide) int {
	count := 0
	for _, h := range homicides {
		if strings.EqualFold(h.CaseClosed, "Closed") {
			count++
		}
	}
	return count
}

func countCameras(homicides []Homicide) int {
	count := 0
	for _, h := range homicides {
		if strings.Contains(strings.ToLower(h.CameraPresent), "camera") {
			count++
		}
	}
	return count
}

func calculateAvgAge(homicides []Homicide) float64 {
	sum := 0.0
	count := 0
	for _, h := range homicides {
		if age, err := strconv.Atoi(h.Age); err == nil {
			sum += float64(age)
			count++
		}
	}
	if count == 0 {
		return 0
	}
	return sum / float64(count)
}

func filterByAgeRange(homicides []Homicide, minAge, maxAge int) []Homicide {
	var filtered []Homicide
	for _, h := range homicides {
		if age, err := strconv.Atoi(h.Age); err == nil {
			if age >= minAge && age <= maxAge {
				filtered = append(filtered, h)
			}
		}
	}
	return filtered
}

func countCriticalZones(hotspots []LocationHotspot) int {
	count := 0
	for _, h := range hotspots {
		if h.TotalCases >= 3 {
			count++
		}
	}
	return count
}

func analyzeAndPrint(homicides []Homicide) {
	results := performAnalysis(homicides)
	
	fmt.Println("\n" + strings.Repeat("=", 80))
	fmt.Println("QUESTION 1: LOCATION-BASED HOTSPOT ANALYSIS")
	fmt.Println(strings.Repeat("=", 80))
	fmt.Printf("\nTotal Homicides Analyzed: %d\n", results.Metadata.TotalHomicides)
	fmt.Printf("Overall Closure Rate: %.2f%%\n", results.Metadata.OverallClosureRate)
	fmt.Printf("Critical Zones (3+ cases): %d\n\n", results.Metadata.CriticalZonesCount)
	
	fmt.Println("Top 10 Location Hotspots:")
	fmt.Println(strings.Repeat("-", 80))
	
	limit := 10
	if len(results.LocationHotspots) < 10 {
		limit = len(results.LocationHotspots)
	}
	
	for i := 0; i < limit; i++ {
		h := results.LocationHotspots[i]
		fmt.Printf("%2d. %s\n", i+1, h.Location)
		fmt.Printf("    Total Cases: %d | Open: %d | Closed: %d | Closure Rate: %.2f%%\n",
			h.TotalCases, h.OpenCases, h.ClosedCases, h.ClosureRate)
		fmt.Printf("    Cameras Present: %d | Avg Victim Age: %.0f\n\n", h.CamerasPresent, h.AvgVictimAge)
	}
	
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println("QUESTION 2: AGE GROUP ANALYSIS")
	fmt.Println(strings.Repeat("=", 80))
	fmt.Println()
	
	for _, ag := range results.AgeGroupAnalysis {
		fmt.Printf("%s:\n", ag.AgeGroup)
		fmt.Printf("  Total Cases: %d | Closed: %d | Open: %d | Closure Rate: %.2f%%\n",
			ag.TotalCases, ag.ClosedCases, ag.OpenCases, ag.ClosureRate)
		fmt.Printf("  Cameras Present: %d\n\n", ag.CamerasPresent)
	}
}
