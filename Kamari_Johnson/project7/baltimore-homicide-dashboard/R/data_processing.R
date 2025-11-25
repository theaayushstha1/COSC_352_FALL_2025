library(rvest)
library(dplyr)
library(stringr)
library(lubridate)
library(tibble)

scrape_year <- function(url, year) {
  page <- read_html(url)
  text <- page %>% html_nodes("body") %>% html_text()

  entries <- str_split(text, "\\n")[[1]]
  entries <- entries[str_detect(entries, "^\\d{1,2}/\\d{1,2}/\\d{2,4}")]

  df <- tibble(raw = entries) %>%
    mutate(
      Date = str_extract(raw, "^\\d{1,2}/\\d{1,2}/\\d{2,4}") %>% mdy(),
      Name = str_extract(raw, "(?<=\\-\\s)[A-Za-z\\s]+(?=,\\s\\d{1,2})"),
      Age = str_extract(raw, "(?<=,\\s)\\d{1,2}(?=\\s[A-Za-z])") %>% as.numeric(),
      Location = str_extract(raw, "(?<=at\\s).*"),
      Year = year
    )
  return(df)
}

load_all_years <- function() {
  cache_path <- "data/homicides.csv"

  if (file.exists(cache_path)) {
    message("Loading cached data from CSV...")
    return(read.csv(cache_path))
  }

  urls <- list(
    "https://chamspage.blogspot.com/2021/" = 2021,
    "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html" = 2022,
    "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html" = 2023,
    "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html" = 2024,
    "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html" = 2025
  )

  message("Scraping fresh data...")
  data <- bind_rows(lapply(names(urls), function(u) scrape_year(u, urls[[u]])))
  write.csv(data, cache_path, row.names = FALSE)
  return(data)
}