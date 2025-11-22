library(rvest)
library(dplyr)
library(stringr)
library(purrr)
library(readr)

urls <- list(
  "2021" = "http://chamspage.blogspot.com/2021/",
  "2022" = "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
  "2023" = "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
  "2024" = "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
  "2025" = "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
)

extract_homicides <- function(year, url) {
  page <- read_html(url)
  text <- page %>% html_elements("li, p, div") %>% html_text2()
  entries <- text[str_detect(text, "\d+\.|[Mm]-\d+")]
  tibble(year = year, raw_entry = entries)
}

all_data <- map2_df(names(urls), urls, extract_homicides)
if (!dir.exists("data")) dir.create("data")
write_csv(all_data, "data/raw_homicides.csv")
