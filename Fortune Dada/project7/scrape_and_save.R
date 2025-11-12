library(rvest)
library(dplyr)
library(stringr)
library(lubridate)
library(purrr)
library(readr)
library(tidyr)

urls <- c(
  "http://chamspage.blogspot.com/2021/",
  "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
  "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
  "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
  "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
)

find_post_nodes <- function(page) {
  sel <- c(".post-body", ".post", ".entry-content", "#main", "article")
  nodes <- NULL
  for (s in sel) {
    nodes <- page %>% html_nodes(s)
    if (length(nodes) > 0) break
  }
  if (length(nodes) == 0) nodes <- list(page)
  nodes
}

extract_lines_from_page <- function(url) {
  page <- tryCatch(read_html(url), error = function(e) return(NULL))
  if (is.null(page)) return(tibble(raw = character(), source = url))
  post_nodes <- find_post_nodes(page)
  tables <- page %>% html_nodes("table")
  if (length(tables) > 0) {
    all_tbl_lines <- tables %>%
      map(~ html_table(.x, fill = TRUE) %>% as_tibble() %>% mutate(.rowid = row_number()) %>% pivot_longer(-.rowid, names_to = "col", values_to = "val") %>% group_by(.rowid) %>% summarise(raw = paste(na.omit(as.character(val)), collapse = " | "), .groups = "drop")) %>%
      bind_rows()
    return(all_tbl_lines %>% mutate(source = url))
  }
  lis <- post_nodes %>% html_nodes("li") %>% html_text(trim = TRUE)
  if (length(lis) > 0) return(tibble(raw = lis, source = url))
  pars <- post_nodes %>% html_nodes("p") %>% html_text(trim = TRUE)
  pars <- pars[nchar(pars) > 10]
  if (length(pars) > 0) return(tibble(raw = pars, source = url))
  txt <- post_nodes %>% html_text()
  lines <- str_split(txt, "\n") %>% unlist() %>% str_trim()
  lines <- lines[nchar(lines) > 5]
  tibble(raw = lines, source = url)
}

parse_raw_line <- function(raw, source) {
  r <- raw %>% str_squish()
  date_pat1 <- "([A-Za-z]+\\s+\\d{1,2},?\\s*(20\\d{2})?)"
  date_pat2 <- "(\\d{1,2}/\\d{1,2}/\\d{2,4})"
  date_found <- str_extract(r, paste0(date_pat1, "|", date_pat2))
  date_parsed <- NA
  if (!is.na(date_found)) {
    date_parsed <- suppressWarnings(parse_date_time(date_found, orders = c("mdy", "BdY", "Ymd", "dby"), quiet = TRUE))
    if (!is.na(date_parsed)) date_parsed <- as.Date(date_parsed)
  }
  age <- str_extract(r, "(?:,|\\(|\\s)(\\d{1,3})(?:\\s?yo|\\s?years|\\s?yrs|\\))")
  if (!is.na(age)) age <- str_extract(age, "\\d{1,3}")
  if (is.na(age)) {
    age2 <- str_extract(r, "age\\s*(\\d{1,3})")
    if (!is.na(age2)) age <- str_extract(age2, "\\d{1,3}")
  }
  name <- NA
  name_match <- str_match(r, "[–—\\-]\\s*([A-Z][\\w'\\-]+(?:\\s+[A-Z][\\w'\\-]+){0,3})")
  if (!is.na(name_match[1,2])) name <- name_match[1,2]
  if (is.na(name)) {
    start_name <- str_match(r, "^([A-Z][\\w'\\-]+(?:\\s+[A-Z][\\w'\\-]+){0,3}),")
    if (!is.na(start_name[1,2])) name <- start_name[1,2]
  }
  location <- NA
  loc1 <- str_match(r, "\\b(?:in|at)\\s+([A-Z][\\w\\-\\s]+(?:,?\\s*[A-Z]{2})?)")
  if (!is.na(loc1[1,2])) location <- str_trim(loc1[1,2])
  if (is.na(location)) {
    parts <- str_split(r, ",")[[1]] %>% map_chr(~ str_trim(.x))
    if (length(parts) >= 2) {
      last <- parts[length(parts)]
      if (!str_detect(last, "\\d") && nchar(last) > 2) location <- last
    }
  }
  tibble(
    raw_line = r,
    source = source,
    date_raw = ifelse(is.na(date_found), NA_character_, as.character(date_found)),
    date_parsed = as.Date(date_parsed),
    year = ifelse(!is.na(date_parsed), as.character(lubridate::year(date_parsed)), NA_character_),
    name = ifelse(is.na(name), NA_character_, name),
    age = ifelse(is.na(age), NA_character_, age),
    location = ifelse(is.na(location), NA_character_, location)
  )
}

all_raw <- map_dfr(urls, extract_lines_from_page)
if (nrow(all_raw) == 0) stop("No raw lines found from pages. Check URLs or connectivity.")
parsed <- pmap_dfr(list(all_raw$raw, all_raw$source), parse_raw_line)
parsed <- parsed %>% filter(!is.na(raw_line) & str_length(raw_line) > 5)
parsed <- parsed %>% mutate(raw_norm = raw_line %>% str_to_lower() %>% str_replace_all("[[:punct:]]", "") %>% str_squish()) %>% distinct(raw_norm, .keep_all = TRUE) %>% select(-raw_norm)
issues <- list()
if (nrow(parsed) == 0) issues <- c(issues, "No parsed rows after extraction.")
if (any(!is.na(parsed$date_parsed) & parsed$date_parsed > Sys.Date())) issues <- c(issues, "Some parsed dates are in the future.")
if (any(is.na(parsed$date_parsed))) issues <- c(issues, paste0(sum(is.na(parsed$date_parsed)), " rows missing a parsed date (may need manual review)."))
final <- parsed %>% select(source, raw_line, date_raw, date_parsed, year, name, age, location)
write_csv(final, "all_homicides.csv")
message("Wrote all_homicides.csv with ", nrow(final), " rows.")
if (length(issues) > 0) {
  message("Validation notes:")
  for (it in issues) message(" - ", it)
} else {
  message("No validation issues detected.")
}
message("\nSample rows:")
print(head(final, 8))
