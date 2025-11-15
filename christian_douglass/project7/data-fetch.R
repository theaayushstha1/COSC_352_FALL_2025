# data-fetch.R
# Downloads and parses Baltimore homicide lists (2021-2025) from provided blog pages

library(rvest)
library(tidyverse)

urls <- c(
  "http://chamspage.blogspot.com/2021/",
  "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
  "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
  "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
  "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
)

dir.create("data", showWarnings = FALSE)

all_rows <- list()

for (u in urls) {
  message("Fetching: ", u)
  try({
    doc <- read_html(u)

    # Try common article containers; fall back to whole body
    nodes <- html_nodes(doc, "article, .post, .post-body, .entry-content, body")
    texts <- nodes %>% html_text2()

    # split into candidate lines
    lines <- unlist(str_split(texts, "\n"))
    lines <- str_trim(lines)
    lines <- lines[lines != ""]

    # Keep lines that look like homicide entries: start with a date or contain a victim name pattern
    candidates <- lines[str_detect(lines, "\\d{1,2}/\\d{1,2}/\\d{2,4}|Victim|Homicide|Killed|date|Date", ignore_case = TRUE)]
    if (length(candidates) == 0) candidates <- lines

    # Simple parser: attempt to extract a leading date and rest as description
    rows <- tibble(raw = candidates) %>%
      mutate(
        date_text = str_extract(raw, "\\b\\d{1,2}/\\d{1,2}/\\d{2,4}\\b"),
        date_text = if_else(is.na(date_text), str_extract(raw, "\\b[A-Za-z]{3,9}\\s+\\d{1,2},?\\s*\\d{4}\\b"), date_text),
        year_from_url = str_extract(u, "\\\\20\\d{2}\\b"),
        # If we couldn't find a date but we have a year in the url, append that year as fallback
        date_parsed = case_when(
          !is.na(date_text) ~ lubridate::parse_date_time(date_text, orders = c('m/d/Y','m/d/y','B d, Y','b d, Y')), 
          !is.na(year_from_url) ~ lubridate::ymd(paste0(year_from_url, "-01-01")),
          TRUE ~ as.Date(NA)
        ),
        # Try to extract age, sex, race using some heuristics
        age = str_extract(raw, "\\b\\d{1,2}\\b(?=(?:,| yr| years| y/o))"),
        sex = if_else(str_detect(raw, "\b(Male|Female|M|F)\b", ignore_case = TRUE), str_extract(raw, "\b(Male|Female|M|F)\b"), NA_character_),
        location = str_extract(raw, "(?<=in\\s)[A-Za-z0-9\s.-]{3,60}"),
        note = raw
      )

    all_rows[[u]] <- rows
  }, silent = TRUE)
}

df <- bind_rows(all_rows, .id = "source_url")

# Clean and normalize
df2 <- df %>%
  mutate(
    date = as.Date(date_parsed),
    year = if_else(is.na(date) & !is.na(source_url), as.integer(str_extract(source_url, "\\b20\\d{2}\\b")), lubridate::year(date)),
    age = as.integer(age),
    sex = if_else(!is.na(sex), str_to_title(sex), NA_character_),
    location = str_trim(location)
  ) %>%
  select(source_url, date, year, age, sex, location, note, raw)

write_csv(df2, "data/homicides.csv")
message("Wrote data/homicides.csv (rows: ", nrow(df2), ")")
