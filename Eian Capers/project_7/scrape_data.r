#library(rvest)
#library(dplyr)
#library(httr)

# Function to scrape a single year's data
#scrape_year <- function(url, year) {
  #cat(paste0("\n", strrep("=", 50), "\n"))
  #cat(paste0("Scraping year: ", year, "\n"))
  #cat(paste0("URL: ", url, "\n"))
  #cat(strrep("=", 50), "\n")
  
  #tryCatch({
    # Read the webpage with user agent
    #page <- GET(url, user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"))
    
    #if (status_code(page) != 200) {
      #cat(paste0("Error: HTTP status ", status_code(page), "\n"))
      #return(NULL)
    #}
    
    webpage <- read_html(page)
    
    # Find all tables
    tables <- html_nodes(webpage, "table")
    
    if (length(tables) == 0) {
      cat("No tables found on page\n")
      return(NULL)
    }
    
    cat(paste0("Found ", length(tables), " table(s)\n"))
    
    # Try to parse each table
    all_data <- NULL
    for (i in seq_along(tables)) {
      table_data <- tryCatch({
        html_table(tables[[i]], fill = TRUE)
      }, error = function(e) {
        NULL
      })
      
      if (!is.null(table_data) && nrow(table_data) > 0) {
        # Check if this looks like homicide data (has expected columns)
        col_names <- names(table_data)
        
        # Look for key column indicators
        has_date <- any(grepl("date|died", tolower(col_names)))
        has_name <- any(grepl("name", tolower(col_names)))
        
        if (has_date || ncol(table_data) >= 7) {
          cat(paste0("  Table ", i, ": ", nrow(table_data), " rows, ", ncol(table_data), " columns\n"))
          
          # Standardize column names
          if (ncol(table_data) >= 9) {
            names(table_data) <- c("No", "DateDied", "Name", "Age", "Address", 
                                    "Notes", "NoViolentHistory", "SurveillanceCamera", "CaseClosed")
          } else if (ncol(table_data) >= 7) {
            # Fill missing columns
            while (ncol(table_data) < 9) {
              table_data <- cbind(table_data, "")
            }
            names(table_data) <- c("No", "DateDied", "Name", "Age", "Address", 
                                    "Notes", "NoViolentHistory", "SurveillanceCamera", "CaseClosed")
          }
          
          # Filter out header rows and empty rows
          table_data <- table_data %>%
            filter(
              !is.na(No) & No != "" & No != "No" & No != "No.",
              !is.na(DateDied) & DateDied != "" & DateDied != "Date Died"
            )
          
          if (nrow(table_data) > 0) {
            table_data$Year <- year
            all_data <- bind_rows(all_data, table_data)
          }
        }
      }
    }
    
    if (!is.null(all_data)) {
      cat(paste0("Extracted ", nrow(all_data), " records for ", year, "\n"))
    } else {
      cat("No valid data extracted\n")
    }
    
    return(all_data)
    
  }, error = function(e) {
    cat(paste0("Error scraping ", year, ": ", e$message, "\n"))
    return(NULL)
  })
}

# Main scraping function
cat("\n")
cat(strrep("=", 70), "\n")
cat("BALTIMORE HOMICIDE DATA SCRAPER\n")
cat(strrep("=", 70), "\n")

# Define URLs for each year
urls <- list(
  list(year = 2021, url = "http://chamspage.blogspot.com/2021/"),
  list(year = 2022, url = "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html"),
  list(year = 2023, url = "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html"),
  list(year = 2024, url = "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html"),
  list(year = 2025, url = "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html")
)

# Scrape all years
all_homicide_data <- NULL

for (item in urls) {
  year_data <- scrape_year(item$url, item$year)
  if (!is.null(year_data)) {
    all_homicide_data <- bind_rows(all_homicide_data, year_data)
  }
  Sys.sleep(2)  # Be polite to the server
}

# Save to CSV
if (!is.null(all_homicide_data) && nrow(all_homicide_data) > 0) {
  output_file <- "homicide_data.csv"
  write.csv(all_homicide_data, output_file, row.names = FALSE)
  
  cat("\n")
  cat(strrep("=", 70), "\n")
  cat("SCRAPING COMPLETE!\n")
  cat(strrep("=", 70), "\n")
  cat(paste0("Total records: ", nrow(all_homicide_data), "\n"))
  cat(paste0("Years covered: ", paste(unique(all_homicide_data$Year), collapse = ", "), "\n"))
  cat(paste0("Output file: ", output_file, "\n"))
  
  # Summary by year
  cat("\nRecords by year:\n")
  summary_by_year <- all_homicide_data %>%
    group_by(Year) %>%
    summarise(Count = n()) %>%
    arrange(Year)
  print(summary_by_year)
  
} else {
  cat("\nERROR: No data was scraped!\n")
  quit(status = 1)
}


cat("\nData scraping successful!\n")
*/