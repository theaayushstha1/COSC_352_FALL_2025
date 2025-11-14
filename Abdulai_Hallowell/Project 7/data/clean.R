library(tidyverse)
library(stringr)

raw <- read_csv("data/homicides_raw.csv")

cleaned <- raw %>%
  # Drop boilerplate / non-data lines
  filter(
    !str_detect(raw, regex("This is a list", ignore_case = TRUE)),
    !str_detect(raw, regex("homicide list may be found", ignore_case = TRUE)),
    !str_detect(raw, regex("Below is a map", ignore_case = TRUE)),
    !str_detect(raw, regex("Homicide Map", ignore_case = TRUE)),
    !str_detect(raw, regex("boundary", ignore_case = TRUE)),
    !str_detect(raw, regex("Legend", ignore_case = TRUE)),
    !str_detect(raw, regex("Blogger is not", ignore_case = TRUE)),
    !str_detect(raw, regex("Blogger note", ignore_case = TRUE)),
    !str_detect(raw, regex("Comment Rules", ignore_case = TRUE)),
    !str_detect(raw, regex("Detroit Homicide", ignore_case = TRUE)),
    # Drop script / tracking blobs
    !str_detect(raw, regex("function\\(", ignore_case = TRUE)),
    !str_detect(raw, regex("facebook", ignore_case = TRUE)),
    !str_detect(raw, regex("gtag\\(", ignore_case = TRUE)),
    !str_detect(raw, regex("embed-container", ignore_case = TRUE))
  ) %>%
  # Remove very short junk lines
  filter(nchar(raw) > 80)

write_csv(cleaned, "data/homicides_clean.csv")
