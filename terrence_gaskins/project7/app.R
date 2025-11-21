library(shiny)
library(rvest)
library(dplyr)
library(leaflet)
library(DT)

# Load and clean data (simplified)
load_data <- function() {
  url <- "http://champspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
  page <- read_html(url)
  items <- html_nodes(page, "li")
  text <- html_text(items)
  tibble(raw = text) %>%
    mutate(date = str_extract(raw, "\\d{1,2}/\\d{1,2}/\\d{4}"))
}

ui <- fluidPage(
  titlePanel("Baltimore Homicides Dashboard"),
  dataTableOutput("table")
)

server <- function(input, output) {
  data <- load_data()
  output$table <- renderDataTable(data)
}

shinyApp(ui, server)
