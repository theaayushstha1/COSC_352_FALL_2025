Project 5: Baltimore Homicide Analysis - Multi-Format Output
Overview
This project analyzes Baltimore homicide data from https://chamspage.blogspot.com/ and outputs the results in three different formats: stdout (default), CSV, and JSON.

Usage
Default Output (stdout)
bash
./run.sh
CSV Output
bash
./run.sh --output=csv
Creates a file: homicide_analysis.csv

JSON Output
bash
./run.sh --output=json
Creates a file: homicide_analysis.json

Data Format Rationale
CSV Format
The CSV format was designed to be easily imported into spreadsheet applications (Excel, Google Sheets) and queryable by data analysis tools (Python pandas, R, SQL).

Structure:

Header Row: category,subcategory,count,percentage,description
Data Rows: Each row represents a specific metric with hierarchical categories
Design Decisions:

Hierarchical Categories: Using category and subcategory columns allows for easy grouping and filtering
Example: All rows with category="victim_type" show victim breakdowns
Example: All rows with category="case_status" show closure rates
Always Include Counts AND Percentages: Both raw numbers and percentages are provided to support different analysis needs
Description Field: Human-readable descriptions make the CSV self-documenting
Use Cases:

Import into Excel for pivot tables and charts
Load into pandas: df = pd.read_csv('homicide_analysis.csv')
Aggregate multiple time periods by appending rows with timestamps
Easy to merge with other CSV datasets
Example CSV Output:

category,subcategory,count,percentage,description
total_victims,all,49,100.00,Total number of victims
victim_type,stabbing,1,2.04,Victims of stabbing
victim_type,shooting,44,89.80,Victims of shooting
JSON Format
The JSON format was designed for API consumption, web applications, and programmatic processing.

Structure:

json
{
  "analysis_metadata": { ... },
  "question_1": {
    "question": "...",
    "total_victims": { "count": ..., "percentage": ... },
    "victim_breakdown": { ... }
  },
  "question_2": { ... }
}
Design Decisions:

Nested Structure: Mirrors the logical hierarchy of the analysis questions
Top-level keys: analysis_metadata, question_1, question_2
Each question contains its own context and results
Metadata Section: Includes source URL and total victims for context and validation
Consistent Object Pattern: Every data point includes both count and percentage as an object
json
   "stabbing": {
     "count": 1,
     "percentage": 2.04
   }
Self-Documenting: Question text is embedded in the JSON for clarity
Easy to Parse: Standard JSON structure works with any programming language
JavaScript: const data = JSON.parse(file)
Python: data = json.load(file)
Java/Scala: Standard JSON libraries
Use Cases:

REST API responses for web dashboards
Mobile app data consumption
Automated report generation
Integration with JavaScript visualization libraries (D3.js, Chart.js)
NoSQL database storage (MongoDB, etc.)
Example JSON Output:

json
{
  "analysis_metadata": {
    "source": "https://chamspage.blogspot.com/",
    "total_victims_analyzed": 49
  },
  "question_1": {
    "question": "What is the ratio of stabbing victims and shooting victims compared to the total?",
    "victim_breakdown": {
      "stabbing": { "count": 1, "percentage": 2.04 },
      "shooting": { "count": 44, "percentage": 89.80 }
    }
  }
}
Analysis Questions
Question 1: Victim Type Distribution
What is the ratio of stabbing victims and shooting victims compared to the total?

This analysis categorizes homicide victims by weapon type (stabbing vs. shooting) to understand the predominant methods of violence in Baltimore.

Question 2: Case Closure Rates
Of these victims (stabbing or shooting), what is the ratio of closed cases?

This analysis examines the closure rate for violent crimes (stabbings and shootings) to assess investigative effectiveness and identify patterns in case resolution.

Technical Details
Dependencies
Docker
Scala 3.3.1
Java 17 (eclipse-temurin)
File Outputs
CSV: homicide_analysis.csv - Created in the project directory
JSON: homicide_analysis.json - Created in the project directory
Data Source
Live data fetched from: https://chamspage.blogspot.com/

Future Enhancements
Add timestamp to output files for historical tracking
Support for date range filtering
Additional analysis questions (geographic distribution, time trends)
Support for multiple data sources
