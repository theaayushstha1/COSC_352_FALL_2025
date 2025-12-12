// main.go
package main

import (
    "encoding/csv"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "os"
    "regexp"
    "strconv"
    "strings"
)

type Homicide struct {
    Number            string `json:"No"`
    DateDied          string `json:"DateDied"`
    Name              string `json:"Name"`
    AgeRaw            string `json:"Age"`
    Address           string `json:"Address"`
    Notes             string `json:"Notes"`
    NoViolentHistory  string `json:"NoViolentHistory"`
    Surveillance      string `json:"Surveillance"`
    CaseClosed        string `json:"CaseClosed"`
}

func (h *Homicide) AgeOpt() (int, bool) {
    digits := ""
    for _, ch := range h.AgeRaw {
        if ch < '0' || ch > '9' {
            break
        }
        digits += string(ch)
    }
    if digits != "" {
        age, err := strconv.Atoi(digits)
        if err == nil {
            return age, true
        }
    }
    return 0, false
}

func (h *Homicide) HasCamera() bool {
    s := strings.TrimSpace(strings.ToLower(h.Surveillance))
    return s != "" && !strings.Contains(s, "none")
}

func (h *Homicide) IsClosed() bool {
    return strings.Contains(strings.ToLower(h.CaseClosed), "closed")
}

func (h *Homicide) Cause() string {
    n := strings.ToLower(h.Notes)
    if strings.Contains(n, "shoot") {
        return "Shooting"
    } else if strings.Contains(n, "stab") {
        return "Stabbing"
    } else if strings.Contains(n, "blunt") || strings.Contains(n, "struck") {
        return "Blunt Force"
    }
    return "Other"
}

// Fetch HTML from URL
func fetch(url string) (string, error) {
    resp, err := http.Get(url)
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()
    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return "", err
    }
    return string(body), nil
}

func cleanCell(s string) string {
    reTag := regexp.MustCompile(`(?is)<[^>]+>`)
    noTags := reTag.ReplaceAllString(s, " ")
    unescaped := strings.NewReplacer(
        "&nbsp;", " ",
        "&amp;", "&",
        "&lt;", "<",
        "&gt;", ">",
    ).Replace(noTags)
    return strings.Join(strings.Fields(unescaped), " ")
}

func parseTable(html string) []Homicide {
    rowRe := regexp.MustCompile(`(?is)<tr[^>]*>(.*?)</tr>`)
    cellRe := regexp.MustCompile(`(?is)<t[dh][^>]*>(.*?)</t[dh]>`)
    rows := rowRe.FindAllStringSubmatch(html, -1)
    parsedRows := [][]string{}
    for _, row := range rows {
        cells := cellRe.FindAllStringSubmatch(row[1], -1)
        parsed := []string{}
        for _, cell := range cells {
            parsed = append(parsed, cleanCell(cell[1]))
        }
        parsedRows = append(parsedRows, parsed)
    }
    // Find header index
    headerIdx := -1
    for i, cells := range parsedRows {
        joined := strings.ToLower(strings.Join(cells, "|"))
        if strings.Contains(joined, "date died") && strings.Contains(joined, "case closed") {
            headerIdx = i
            break
        }
    }
    dataRows := parsedRows
    if headerIdx >= 0 {
        dataRows = parsedRows[headerIdx+1:]
    }
    homicides := []Homicide{}
    for _, cells := range dataRows {
        if len(cells) >= 9 && regexp.MustCompile(`^\d+$`).MatchString(cells[0]) {
            h := Homicide{
                Number:           cells[0],
                DateDied:         cells[1],
                Name:             cells[2],
                AgeRaw:           cells[3],
                Address:          cells[4],
                Notes:            cells[5],
                NoViolentHistory: cells[6],
                Surveillance:     cells[7],
                CaseClosed:       cells[8],
            }
            homicides = append(homicides, h)
        }
    }
    return homicides
}

func pct(num, den int) float64 {
    if den == 0 {
        return 0.0
    }
    return float64(num) / float64(den) * 100.0
}

func avgAge(homicides []Homicide) (float64, bool) {
    sum := 0
    count := 0
    for _, h := range homicides {
        age, ok := h.AgeOpt()
        if ok {
            sum += age
            count++
        }
    }
    if count > 0 {
        return float64(sum) / float64(count), true
    }
    return 0.0, false
}

// Write CSV
func writeCSV(homicides []Homicide, filename string) error {
    file, err := os.Create(filename)
    if err != nil {
        return err
    }
    defer file.Close()
    writer := csv.NewWriter(file)
    defer writer.Flush()
    header := []string{"No", "DateDied", "Name", "Age", "Address", "Notes", "NoViolentHistory", "Surveillance", "CaseClosed"}
    writer.Write(header)
    for _, h := range homicides {
        writer.Write([]string{
            h.Number, h.DateDied, h.Name, h.AgeRaw, h.Address,
            h.Notes, h.NoViolentHistory, h.Surveillance, h.CaseClosed,
        })
    }
    return nil
}

// Write JSON
func writeJSON(homicides []Homicide, filename string) error {
    file, err := os.Create(filename)
    if err != nil {
        return err
    }
    defer file.Close()
    encoder := json.NewEncoder(file)
    encoder.SetIndent("", "  ")
    return encoder.Encode(homicides)
}

func question1_CamerasVsClosure(data []Homicide) {
    withCam := []Homicide{}
    withoutCam := []Homicide{}
    for _, h := range data {
        if h.HasCamera() {
            withCam = append(withCam, h)
        } else {
            withoutCam = append(withoutCam, h)
        }
    }
    closedWithCam := 0
    for _, h := range withCam {
        if h.IsClosed() {
            closedWithCam++
        }
    }
    closedWithout := 0
    for _, h := range withoutCam {
        if h.IsClosed() {
            closedWithout++
        }
    }
    rateWith := pct(closedWithCam, len(withCam))
    rateWithout := pct(closedWithout, len(withoutCam))
    avgAgeWith, _ := avgAge(withCam)
    avgAgeWithout, _ := avgAge(withoutCam)
    fmt.Println("Question 1: How do case closure rates differ when a surveillance camera is present versus absent at the intersection? (and what are the average victim ages)")
    fmt.Printf("- WITH camera: count=%d closed=%d rate=%.2f%% avgAge=%.2f\n", len(withCam), closedWithCam, rateWith, avgAgeWith)
    fmt.Printf("- WITHOUT camera: count=%d closed=%d rate=%.2f%% avgAge=%.2f\n", len(withoutCam), closedWithout, rateWithout, avgAgeWithout)
    fmt.Printf("- Insight: Presence of cameras corresponds to a %.2f%% absolute difference in closure rate.\n\n", rateWith-rateWithout)
}

func question2_CauseVsClosure(data []Homicide) {
    byCause := map[string][]Homicide{}
    for _, h := range data {
        cause := h.Cause()
        byCause[cause] = append(byCause[cause], h)
    }
    fmt.Println("Question 2: What are closure rates by likely cause inferred from Notes (Shooting vs Stabbing vs Other)?\n")
    rates := map[string]float64{}
    for cause, homs := range byCause {
        closed := 0
        for _, h := range homs {
            if h.IsClosed() {
                closed++
            }
        }
        rate := pct(closed, len(homs))
        avg, _ := avgAge(homs)
        rates[cause] = rate
        fmt.Printf("- %s: count=%d closed=%d rate=%.2f%% avgAge=%.2f\n", cause, len(homs), closed, rate, avg)
    }
    // Find max/min
    var maxCause, minCause string
    var maxRate, minRate float64
    for cause, rate := range rates {
        if rate > maxRate || maxCause == "" {
            maxRate = rate
            maxCause = cause
        }
        if rate < minRate || minCause == "" {
            minRate = rate
            minCause = cause
        }
    }
    fmt.Printf("\n- Insight: Highest closure rate category = %s at %.2f%%; lowest = %s at %.2f%%.\n\n", maxCause, maxRate, minCause, minRate)
}

func main() {
    urls := []string{
        "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html",
        "http://chamspage.blogspot.com",
    }
    var html string
    for _, u := range urls {
        h, err := fetch(u)
        if err == nil {
            html = h
            break
        }
    }
    if html == "" {
        fmt.Println("Error: Unable to download homicide table from chamspage.")
        os.Exit(1)
    }
    homicides := parseTable(html)
    if len(homicides) == 0 {
        fmt.Println("No homicide rows were parsed; the source page structure may have changed.")
        os.Exit(1)
    }
    // Output arguments
    args := os.Args[1:]
    var outputFormat string
    for _, arg := range args {
        if strings.HasPrefix(arg, "--output=") {
            val := strings.ToLower(strings.TrimPrefix(arg, "--output="))
            if val == "csv" || val == "json" {
                outputFormat = val
            }
        }
    }
    switch outputFormat {
    case "":
        // Default: print analytics to stdout
        fmt.Println(strings.Repeat("=", 80))
        question1_CamerasVsClosure(homicides)
        fmt.Println(strings.Repeat("=", 80))
        question2_CauseVsClosure(homicides)
        fmt.Println(strings.Repeat("=", 80))
    case "csv":
        csvPath := "/output/output.csv"
        if _, err := os.Stat("/output"); os.IsNotExist(err) {
            csvPath = "output.csv"
        }
        if err := writeCSV(homicides, csvPath); err != nil {
            fmt.Println("Failed to write CSV:", err)
        } else {
            fmt.Println("CSV data written to", csvPath)
        }
    case "json":
        jsonPath := "/output/output.json"
        if _, err := os.Stat("/output"); os.IsNotExist(err) {
            jsonPath = "output.json"
        }
        if err := writeJSON(homicides, jsonPath); err != nil {
            fmt.Println("Failed to write JSON:", err)
        } else {
            fmt.Println("JSON data written to", jsonPath)
        }
    default:
        fmt.Println("Unknown output format:", outputFormat)
    }
}
