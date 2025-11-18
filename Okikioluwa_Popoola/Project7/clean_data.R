library(dplyr)
library(stringr)
library(readr)
library(lubridate)

raw <- read_csv("data/raw_homicides.csv")

cleaned <- raw %>%
  mutate(
    case_number = str_extract(raw_entry, "^\d+"),
    name = str_extract(raw_entry, "(?<=\. ).*?(?=, \d)"),
    age = str_extract(raw_entry, "\d+(?=,)"),
    method = case_when(
      str_detect(raw_entry, "shot") ~ "Shooting",
      str_detect(raw_entry, "stab") ~ "Stabbing",
      str_detect(raw_entry, "struck") ~ "Assault",
      TRUE ~ "Other"
    ),
    date = str_extract(raw_entry, "\b\w+ \d{1,2}, \d{4}\b"),
    gender = case_when(
      str_detect(raw_entry, "male|Male|M") ~ "Male",
      str_detect(raw_entry, "female|Female|F") ~ "Female",
      TRUE ~ NA
    )
  )

write_csv(cleaned, "data/homicides_clean.csv")
