library(rvest)
library(tidyverse)

urls <- tribble(
  ~year, ~url,
  2021, "http://chamspage.blogspot.com/2021/",
  2022, "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
  2023, "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
  2024, "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
  2025, "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
)

scrape_year <- function(url, year) {
  page <- read_html(url)

  body <- page %>% html_elements(".post-body")
  text <- body %>% html_text2()

  lines <- str_split(text, "\n|\\r|\\s{2,}", simplify = FALSE)[[1]]

  tibble(
    year = year,
    raw = str_trim(lines)
  ) %>%
    filter(raw != "")
}

data <- map2_dfr(urls$url, urls$year, scrape_year)

write_csv(data, "data/homicides_raw.csv")
