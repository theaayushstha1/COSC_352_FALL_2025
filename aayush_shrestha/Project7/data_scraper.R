library(rvest)
library(dplyr)
library(stringr)
library(httr)

scrape_homicide_data <- function(url, year) {
  tryCatch({
    # Add user agent to avoid blocking
    page <- read_html(GET(url, user_agent("Mozilla/5.0")))
    
    # Extract ALL tables from the page
    tables <- page %>% html_table(fill = TRUE)
    
    if(length(tables) == 0) {
      cat("No tables found for", year, "\n")
      return(NULL)
    }
    
    # Find the correct table (usually the first big one)
    data <- NULL
    for(i in 1:length(tables)) {
      if(ncol(tables[[i]]) >= 8 && nrow(tables[[i]]) > 10) {
        data <- tables[[i]]
        break
      }
    }
    
    if(is.null(data)) {
      cat("No valid table found for", year, "\n")
      return(NULL)
    }
    
    # Clean and standardize column names
    colnames(data) <- c("No", "Date_Died", "Name", "Age", "Address", 
                        "Notes", "No_Violent_History", "Camera", "Case_Closed")[1:ncol(data)]
    
    # If missing Case_Closed column, add it
    if(ncol(data) < 9) {
      data$Case_Closed <- "Unknown"
    }
    
    # Add year column
    data$Year <- year
    
    # Filter out header rows and empty rows
    data <- data %>% 
      filter(!is.na(No) & No != "No." & No != "--" & No != "" & No != "No") %>%
      filter(row_number() > 0)
    
    # Clean Age column - remove non-numeric characters
    data$Age <- as.numeric(gsub("[^0-9]", "", data$Age))
    
    cat("Successfully scraped", nrow(data), "records for", year, "\n")
    return(data)
    
  }, error = function(e) {
    cat("Error scraping", year, ":", e$message, "\n")
    return(NULL)
  })
}

load_all_data <- function() {
  urls <- list(
    "2021" = "http://chamspage.blogspot.com/2021/",
    "2022" = "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
    "2023" = "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
    "2024" = "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
    "2025" = "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
  )
  
  all_data <- list()
  
  for(year in names(urls)) {
    cat("\n=== Scraping", year, "===\n")
    data <- scrape_homicide_data(urls[[year]], year)
    if(!is.null(data) && nrow(data) > 0) {
      all_data[[year]] <- data
    }
    Sys.sleep(1)  # Be polite to the server
  }
  
  if(length(all_data) == 0) {
    cat("\nWARNING: No data was scraped!\n")
    return(data.frame())
  }
  
  combined_data <- bind_rows(all_data)
  
  cat("\n=== SCRAPING COMPLETE ===\n")
  cat("Total records scraped:", nrow(combined_data), "\n")
  cat("Years covered:", paste(unique(combined_data$Year), collapse=", "), "\n")
  
  return(combined_data)
}
