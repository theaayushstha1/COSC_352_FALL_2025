library(rvest)
library(dplyr)
library(stringr)
library(lubridate)
library(purrr)
library(readr)

urls <- list(
  "2021" = "http://chamspage.blogspot.com/2021/",
  "2022" = "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
  "2023" = "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
  "2024" = "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
  "2025" = "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
)

clean_table <- function(tbl, year_hint = NA) {
  names(tbl) <- make.names(names(tbl))

  tbl <- tbl %>% rename_with(
    ~ str_replace_all(.x, c(
      "No\\." = "No",
      "Date.Died" = "DateDied",
      "Date" = "DateDied",
      "Address.Block" = "Address"
    )),
    everything()
  )

  required_cols <- c("DateDied", "Age", "Name", "Address", "Notes")
  for (col in required_cols) {
    if (!col %in% names(tbl)) tbl[[col]] <- NA
  }

 if (!"DateDied" %in% names(tbl) || all(is.na(tbl$DateDied))) {
  datecol <- which(sapply(tbl, function(x) any(grepl("\\d{1,2}/\\d{1,2}/", x))))
  if (length(datecol)) names(tbl)[datecol[1]] <- "DateDied"
}


  tbl <- tbl %>% mutate(
    DateDied_parsed = suppressWarnings(mdy(DateDied)),
    Year = ifelse(!is.na(DateDied_parsed), year(DateDied_parsed), year_hint),
    Age_num = suppressWarnings(parse_number(Age))
  )

  return(tbl)
}

fetch_one <- function(url, year_hint = NA) {
  cat("Fetching:", url, "\n")
  page <- read_html(url)

  tbs <- page %>% html_nodes("table")
  if (length(tbs) == 0) stop("No table found at:", url)

  tables <- lapply(tbs, html_table, fill = TRUE)
  tbl <- tables[[which.max(sapply(tables, nrow))]]

  clean_table(tbl, year_hint)
}

all_data <- imap_dfr(urls, ~ {
  t <- tryCatch(
    fetch_one(.x, year_hint = as.integer(.y)),
    error = function(e) { message("Error:", e$message); return(NULL) }
  )
  if (!is.null(t)) t$source_url <- .x
  t
})

dir.create("data", showWarnings = FALSE)
write_csv(all_data, "data/baltimore_homicides_2021_2025_clean.csv")

cat("Saved cleaned data to data/baltimore_homicides_2021_2025_clean.csv\n")
