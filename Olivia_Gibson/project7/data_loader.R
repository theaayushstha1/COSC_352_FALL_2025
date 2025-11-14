library(rvest)
library(dplyr)
library(stringr)
library(lubridate)

# List of URLs for each year's homicide data
urls <- c(
  "https://chamspage.blogspot.com/2021/",
  "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
  "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
  "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
  "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
)

# Function to load and clean data from each URL
load_homicide_data <- function(urls) {
  all_data <- lapply(urls, function(url) {
    message("Loading data from: ", url)
    
    page <- tryCatch(read_html(url), error = function(e) {
      message("Failed to read: ", url)
      return(NULL)
    })
    
    if (is.null(page)) return(NULL)
    
    tables <- html_table(html_nodes(page, "table"), fill = TRUE)
    if (length(tables) == 0) {
      message("No tables found at: ", url)
      return(NULL)
    }
    
    table <- tables[[1]]
    
    # Add year column
    year <- str_extract(url, "\\d{4}")
    table$year <- year
    
    # Standardize column names
    names(table) <- tolower(gsub("[^A-Za-z0-9]", "_", names(table)))
    
    # Rename common columns for clarity (adjust as needed)
    colnames(table)[colnames(table) == "x3"] <- "name"
    colnames(table)[colnames(table) == "x5"] <- "location"
    
    # Clean date column if it exists
    if ("date" %in% names(table)) {
      table$date <- parse_date_time(table$date, orders = c("mdy", "ymd", "dmy"))
    }
    
    return(table)
  })
  
  bind_rows(Filter(Negate(is.null), all_data))
}

# Load the data
homicide_data <- load_homicide_data(urls)
