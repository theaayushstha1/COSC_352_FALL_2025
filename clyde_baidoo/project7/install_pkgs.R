# Use RSPM for faster installs
options(repos = c(
  RSPM = "https://packagemanager.posit.co/cran/__linux__/jammy/latest"
))

# Install required packages (sf removed for faster build)
install.packages(c(
  "shiny",
  "dplyr",
  "ggplot2",
  "plotly",
  "DT",
  "lubridate",
  "rvest",
  "stringr",
  "tidygeocoder",
  "leaflet"
))
