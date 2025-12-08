library(shiny)
library(dplyr)
library(leaflet)
library(DT)
library(lubridate)
library(ggplot2)
library(readr)
library(stringr)

# Load CSV
df <- read_csv("data/baltimore_homicides_2021_2025_clean.csv", show_col_types = FALSE)

# --- Print all column names for inspection ---
cat("Columns in CSV:\n")
print(colnames(df))

# --- Required columns for the app ---
required_cols <- c("DateDied", "Age_num", "Address", "Name", "lat", "lon", "Notes", "Camera", "CaseClosed")

# --- Attempt to find a date column automatically ---
date_col_candidates <- grep("date", colnames(df), ignore.case = TRUE, value = TRUE)

if(length(date_col_candidates) == 0){
  stop("No date column found in the CSV! Check printed column names above.")
}

date_col <- date_col_candidates[1]

# Parse the date column
df$DateDied_parsed <- as.Date(df[[date_col]], tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))
if(all(is.na(df$DateDied_parsed))){
  stop("Failed to parse any dates in the detected date column!")
}

# Create Year column
df$Year <- format(df$DateDied_parsed, "%Y")

# Add missing required columns as NA
for(col in setdiff(required_cols, colnames(df))){
  df[[col]] <- NA
}

# --- UI ---
ui <- fluidPage(
  titlePanel("Baltimore City Homicides (2021–2025)"),
  sidebarLayout(
    sidebarPanel(
      selectInput("year", "Year", choices = c("All", sort(unique(df$Year))), selected = "All"),
      dateRangeInput("daterange", "Date range", 
                     start = min(df$DateDied_parsed, na.rm=TRUE), 
                     end = max(df$DateDied_parsed, na.rm=TRUE)),
      sliderInput("age", "Victim age", min = 0, max = 100, value = c(0,100)),
      textInput("address", "Address / block contains"),
      checkboxInput("only_geocoded", "Only show geocoded (map)", FALSE)
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Map", leafletOutput("map", height = 600)),
        tabPanel("Time Series", plotOutput("tsplot")),
        tabPanel("Table", DTOutput("table"))
      )
    )
  )
)

# --- Server ---
server <- function(input, output, session) {

  filtered <- reactive({
    d <- df
    if (input$year != "All") 
      d <- d %>% filter(Year == as.numeric(input$year))
    d <- d %>% filter(
      DateDied_parsed >= input$daterange[1],
      DateDied_parsed <= input$daterange[2],
      Age_num >= input$age[1], Age_num <= input$age[2]
    )
    if (nzchar(input$address))
      d <- d %>% filter(str_detect(Address, regex(input$address, ignore_case=TRUE)))
    if (input$only_geocoded)
      d <- d %>% filter(!is.na(lat) & !is.na(lon))
    d
  })

  output$map <- renderLeaflet({
    d <- filtered()
    leaflet(d) %>% addTiles() %>% 
      addCircleMarkers(~lon, ~lat, popup = ~paste(Name, "<br>", DateDied_parsed, "<br>", Address))
  })

  output$tsplot <- renderPlot({
    d <- filtered() %>% mutate(week = floor_date(DateDied_parsed, "week"))
    ts <- d %>% group_by(week) %>% summarise(n = n(), .groups = "drop")
    ggplot(ts, aes(x = week, y = n)) + geom_col()
  })

  output$table <- renderDT({
    filtered() %>% 
      select(DateDied_parsed, Name, Age_num, Address, Notes, Camera, CaseClosed)
  })
}

shinyApp(ui, server)
