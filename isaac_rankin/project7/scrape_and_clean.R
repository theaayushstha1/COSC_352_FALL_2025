library(rvest)
library(dplyr)
library(stringr)
library(purrr)
library(readr)

urls <- list(
#   "2021" = "https://chamspage.blogspot.com/2021/01/2021-baltimore-city-homicide-list.html",
  "2022" = "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
  "2023" = "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
  "2024" = "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
  "2025" = "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
)

scrape_year <- function(url, year) {
  message("Scraping: ", url)

  page <- read_html(url)

  # These pages store data inside <p> tags primarily
  raw <- page %>% html_elements("p") %>% html_text()

  # Remove empty lines and headers
  raw <- raw[nchar(raw) > 0]

  tibble(
    year = year,
    text = raw
  )
}

all_data <- imap_dfr(urls, scrape_year)

write_csv(all_data, "/srv/shiny-server/app/homicides_all.csv")
