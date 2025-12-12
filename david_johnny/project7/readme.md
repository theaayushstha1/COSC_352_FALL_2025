Project: Baltimore Homicide Analysis - R Shiny Dashboard
Overview
This project creates an interactive web dashboard that analyzes Baltimore homicide data from https://chamspage.blogspot.com/ (2021-2025). The dashboard provides real-time data scraping, interactive filtering, and visualizations to explore homicide patterns in Baltimore City.
This is an R Shiny implementation that provides a web-based interface for exploring the data, in contrast to command-line analysis tools. It leverages R's strengths in data analysis, visualization, and creating interactive applications.
Requirements

Docker
Docker Compose (recommended)
Web browser

Usage
Quick Start with Docker Compose (Recommended)

Make sure all files are in the same directory:

   baltimore-homicides/
   ├── Dockerfile
   ├── docker-compose.yml
   ├── app.R
   └── README.md

Build and start the application:

bash   docker-compose up -d

Access the dashboard:
Open your web browser to: http://localhost:3838/baltimore-homicides/
Stop the application:

bash   docker-compose down
Alternative: Manual Docker Commands
If you prefer not to use Docker Compose:
bash# Build the Docker image
docker build -t baltimore-homicides .

# Run the container
docker run -d -p 3838:3838 --name baltimore-app baltimore-homicides

# View logs
docker logs baltimore-app

# Stop and remove container
docker stop baltimore-app
docker rm baltimore-app
Viewing Logs
bash# Real-time logs
docker-compose logs -f

# Or with manual Docker
docker logs -f baltimore-app
Dashboard Features
Interactive Filtering

Year Filter: View data for specific years (2021-2025) or all years combined
Name Search: Filter victims by name (case-insensitive search)
Camera Filter: Show only cases mentioning cameras in the notes

Visualizations

Timeline Tab: Daily count of homicides shown as a bar chart
Monthly Trend Tab: Aggregated monthly homicide counts with line graph
Table Tab: Full data table with sorting, searching, and pagination
Diagnostics Tab: System information including record counts and data sources

Data Management

Initial Load: Automatically scrapes all available years on startup
Re-scrape Button: Manually refresh data without restarting the container
Real-time Updates: Changes to filters are reflected immediately

Data Source & Processing
Source
Live data scraped from: https://chamspage.blogspot.com/
Years covered: 2021, 2022, 2023, 2024, 2025
Data Processing Pipeline

Scraping:

Fetches HTML from Chamspage blog
Extracts table data using rvest package
Implements 1-second delay between requests (polite scraping)


Normalization:

Flexible column detection (handles varying table formats)
Extracts: date, name, age, address, notes
Standardizes date formats using lubridate


Enrichment:

Parses dates into standard format
Extracts numeric age values
Cleans and normalizes address/note fields
Assigns unique IDs to each record



Data Fields
FieldDescriptionExampleidUnique record identifier1, 2, 3...dateDate of incident2024-01-15yearExtracted year2024nameVictim nameJohn DoeageVictim age25addressLocation/block1200 block N. Gay StnotesAdditional detailsFound in alley, camera footagesource_urlOriginal data URLhttps://chamspage...
R vs Go/Scala Implementation Differences
1. Language Philosophy

R: Statistical computing and graphics; designed for data analysis
Go/Scala: General-purpose programming languages
R Advantage: Built-in statistical functions, extensive visualization libraries

2. User Interface

R Shiny: Interactive web dashboard with real-time updates
Go/Scala: Command-line output (stdout, CSV, JSON files)
Trade-off: R provides interactivity; CLI tools provide scriptability

3. Data Processing

R: Uses tidyverse (dplyr, tidyr) for data manipulation - highly readable pipeline syntax
Go: Manual loops and data structures
Scala: Functional programming with immutable collections

4. Visualization

R: ggplot2 + plotly for interactive charts - declarative syntax
Go/Scala: No built-in visualization; requires external libraries or file export

5. Web Scraping

R: rvest package - simple, intuitive HTML parsing
Go: net/http + regex - low-level but flexible
Scala: Java interop with scala.io.Source

6. State Management

R Shiny: Reactive programming model - automatic UI updates when data changes
Go/Scala: Stateless execution - runs once and exits

7. Deployment

R Shiny:

Requires Shiny Server
Docker image: ~800MB-1GB (includes R + packages)
Always-on web service


Go:

Static binary, no dependencies
Docker image: ~10-15MB
Run-once CLI tool


Scala:

Requires JVM
Docker image: ~600-800MB
Run-once CLI tool



8. Error Handling

R: Uses tryCatch with condition system
Go: Explicit error values (if err != nil)
Scala: Exception-based with try-catch

9. Performance Characteristics

R Shiny:

Initial load: 5-10 seconds (scraping + processing)
Memory: ~200-500MB (data + Shiny server)
Concurrent users: Supports multiple simultaneous sessions


Go:

Execution: Sub-second
Memory: ~10-50MB
Single-threaded execution


Scala:

JVM startup: 1-2 seconds
Memory: ~100-200MB
JVM warmup benefits repeated executions



When to Use This Implementation
Use R Shiny Dashboard when:

✅ Interactive exploration of data is needed
✅ Non-technical users need access to the data
✅ Visualizations are a primary deliverable
✅ Real-time filtering and drill-down are valuable
✅ You want to share findings via a web interface
✅ Ad-hoc analysis patterns are common

Use Go/Scala CLI when:

✅ Automated batch processing is required
✅ Integration into larger pipelines (cron jobs, ETL)
✅ Machine-readable output formats are primary need
✅ Minimal resource footprint is critical
✅ Scheduled reports need to be generated
✅ Data feeds other systems (APIs, databases)

Files Structure
baltimore-homicides/
├── Dockerfile              # Multi-stage build for R Shiny
├── docker-compose.yml      # Orchestration with health checks
├── app.R                   # Main Shiny application
├── .dockerignore          # Optimize Docker builds
└── README.md              # This file
Development Mode
The docker-compose.yml file includes volume mounting for development:
yamlvolumes:
  - ./app.R:/srv/shiny-server/baltimore-homicides/app.R
This means:

Edit app.R on your local machine
Refresh browser to see changes (Shiny auto-reloads)
No need to rebuild the Docker image

For production: Remove the volumes: section from docker-compose.yml
Production Deployment
1. Remove Development Volume Mount
Edit docker-compose.yml and remove:
yaml    volumes:
      - ./app.R:/srv/shiny-server/baltimore-homicides/app.R
2. Add Resource Limits
yaml    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G
        reservations:
          memory: 512M
3. Add Reverse Proxy for HTTPS
Use nginx or Traefik:
nginxserver {
    listen 443 ssl;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:3838;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
4. Enable Authentication (Optional)
Consider adding Shiny Server Pro or nginx basic auth for access control.
5. Set Up Monitoring
The health check endpoint is available:
bashcurl http://localhost:3838/baltimore-homicides/
Use with monitoring tools like Prometheus, Grafana, or Uptime Kuma.
Troubleshooting
Container Won't Start
bash# Check logs for errors
docker logs baltimore-homicides-app

# Common issues:
# - Port 3838 already in use
# - Missing R packages (check Dockerfile)
# - Insufficient memory
Port Already in Use
Change the port mapping in docker-compose.yml:
yamlports:
  - "8080:3838"  # Use port 8080 instead of 3838
Then access at: http://localhost:8080/baltimore-homicides/
Scraping Fails

Check internet connectivity
Verify Chamspage blog is accessible
Review logs: docker logs baltimore-homicides-app
Blog structure may have changed (requires app.R update)

Out of Memory
bash# Check container memory usage
docker stats baltimore-homicides-app

# Increase limit in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 4G
Data Not Updating

Click the "Re-scrape pages" button in the dashboard
If that fails, restart the container:

bash   docker-compose restart
Technical Details
R Package Dependencies

shiny - Web application framework
tidyverse - Data manipulation (dplyr, tidyr, ggplot2, stringr)
rvest - Web scraping
lubridate - Date parsing and manipulation
DT - Interactive tables
plotly - Interactive visualizations

Scraping Behavior

Polite Scraping: 1-second delay between requests
Error Handling: Graceful degradation if pages fail to load
User Agent: Identifies as legitimate scraper
Table Detection: Automatically finds largest table on page

Data Persistence

In-Memory: Data stored in reactive values (lost on restart)
No Database: Simple deployment, no external dependencies
Re-scraping: Available via UI button - no container restart needed

Future Enhancement: Add persistent storage using SQLite or PostgreSQL for historical tracking.
Future Enhancements
Planned Features

 Export filtered data to CSV/JSON from UI
 Geographic heatmap (if geocoding added)
 Year-over-year comparison charts
 Statistical analysis (trends, seasonality)
 Downloadable reports (PDF/HTML)
 User-customizable dashboards
 Email alerts for new cases
 Historical data versioning
 API endpoint for programmatic access

Technical Improvements

 Add unit tests using testthat package
 Implement caching to reduce scraping frequency
 Add database backend (PostgreSQL/SQLite)
 Set up CI/CD pipeline
 Add authentication/authorization
 Optimize memory usage for large datasets
 Add data validation checks
 Implement rate limiting for re-scraping

License & Data Attribution
Code: This implementation is provided as-is for educational and analysis purposes.
Data Source: All homicide data is scraped from Chamspage (https://chamspage.blogspot.com/), which aggregates public information about Baltimore City homicides. Please respect the original data source and use responsibly.
Disclaimer: This is an unofficial analysis tool. For official crime statistics, consult Baltimore Police Department or FBI UCR data.
Contact & Contributions
For issues, suggestions, or contributions, please ensure:

Docker and Docker Compose are up to date
Include relevant logs when reporting issues
Test changes in development mode before proposing
Follow existing code style (tidyverse conventions)


Quick Reference Commands:
bash# Start dashboard
docker-compose up -d

# View logs
docker-compose logs -f

# Stop dashboard
docker-compose down

# Restart (after code changes)
docker-compose restart

# Rebuild (after Dockerfile changes)
docker-compose up -d --build
Access URL: http://localhost:3838/baltimore-homicides/