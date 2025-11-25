# Data Processing Script for Baltimore Homicide Data
# This script extracts data from HTML files and creates a clean CSV

library(rvest)
library(dplyr)
library(lubridate)
library(stringr)
library(tidyr)

# Function to extract homicide data from HTML
extract_homicide_data <- function(html_file, year) {
  tryCatch({
    page <- read_html(html_file)
    
    # Try to find the table - adjust selector as needed
    tables <- page %>% html_table(fill = TRUE)
    
    if (length(tables) > 0) {
      # Get the first table (adjust if needed)
      data <- tables[[1]]
      data$Year <- year
      return(data)
    } else {
      # If no table, try to parse text
      text_content <- page %>% 
        html_nodes("p, div") %>% 
        html_text()
      
      # Create a simple data frame
      data <- data.frame(
        Content = text_content,
        Year = year,
        stringsAsFactors = FALSE
      )
      return(data)
    }
  }, error = function(e) {
    message(paste("Error processing", html_file, ":", e$message))
    return(NULL)
  })
}

# Process all years
years <- 2021:2025
all_data <- list()

for (year in years) {
  file_path <- paste0("data/raw/", year, ".html")
  if (file.exists(file_path)) {
    message(paste("Processing", year, "data..."))
    year_data <- extract_homicide_data(file_path, year)
    if (!is.null(year_data)) {
      all_data[[as.character(year)]] <- year_data
    }
  } else {
    message(paste("Warning:", file_path, "not found. Skipping", year))
  }
}

# Combine all data
if (length(all_data) > 0) {
  combined_data <- bind_rows(all_data)
  
  # Save processed data
  write.csv(combined_data, "data/homicides.csv", row.names = FALSE)
  message("Data processing complete! Saved to data/homicides.csv")
  message(paste("Total records:", nrow(combined_data)))
} else {
  message("No data to process. Please check that HTML files exist in data/raw/")
}
