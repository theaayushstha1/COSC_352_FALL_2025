# R/data_ingest.R
library(rvest)
library(dplyr)
library(stringr)
library(lubridate)
library(purrr)
library(readr)

urls <- list(
  "2021"="http://chamspage.blogspot.com/2021/",
  "2022"="http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
  "2023"="http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
  "2024"="http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
  "2025"="http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
)

parse_chamspage <- function(url, year_label){
  page <- read_html(url)
  tbls <- page %>% html_nodes("table") %>% html_table(fill=TRUE)

  if (length(tbls)==0){
    txt <- page %>% html_node("div.post-body") %>% html_text(trim=TRUE)
    lines <- str_split(txt,"\n")[[1]]
    rows <- lines[str_detect(lines,"^[0-9]{3}|[0-9]{1,2}/[0-9]{1,2}/")]
    df <- tibble(raw=rows)
  } else {
    sizes <- map_int(tbls, nrow)
    df <- tbls[[which.max(sizes)]] %>% as_tibble()
  }

  names(df) <- names(df) %>% tolower() %>% str_replace_all("\s+","_")

  df2 <- df %>% mutate(source_year=year_label, source_url=url) %>%
    rename_with(~ case_when(
      str_detect(.x,"date|died") ~ "date",
      str_detect(.x,"name") ~ "name",
      str_detect(.x,"age") ~ "age",
      str_detect(.x,"address|block") ~ "address_block",
      str_detect(.x,"found|notes|note") ~ "notes",
      str_detect(.x,"camera") ~ "camera",
      str_detect(.x,"closed|case") ~ "case_closed",
      TRUE ~ .x
    ))

  expected <- c("date","name","age","address_block","notes","camera","case_closed","source_year","source_url")
  for (nm in expected) if (!nm %in% names(df2)) df2[[nm]] <- NA

  df2 <- df2 %>% mutate(
    date_parsed = parse_date_time(date, orders=c("mdy","dmy","Ymd","mdY","m/d/Y"), quiet=TRUE),
    date_parsed = if_else(is.na(date_parsed) & str_detect(date,"^\d{1,2}/\d{1,2}$"),
                          parse_date_time(paste0(date,"/",source_year), orders="mdy", quiet=TRUE),
                          date_parsed),
    date = as_date(date_parsed)
  )

  df2 <- df2 %>% mutate(across(c(name,age,address_block,notes,camera,case_closed), ~ if_else(is.na(.x),NA_character_,str_squish(as.character(.x)))))
  df2 %>% mutate(original_row=row_number())
}

parsed <- imap(urls, ~ parse_chamspage(.x,.y))
all <- bind_rows(parsed, .id="from_site") %>%
  mutate(flag_no_date=is.na(date), flag_no_name=is.na(name)|name=="")

dir.create("data/processed", recursive=TRUE, showWarnings=FALSE)
saveRDS(all, "data/processed/homicides_2021_2025.rds")
write_csv(all, "data/processed/homicides_2021_2025.csv")
