library(shiny)
library(DT)
library(leaflet)
library(dplyr)
library(lubridate)

# Load the data
source("data_loader.R")

# UI layout
ui <- fluidPage(
  titlePanel("Baltimore Homicide Dashboard"),
  sidebarLayout(
    sidebarPanel(
      selectInput("year", "Select Year", choices = unique(homicide_data$year), selected = "2025"),
      textInput("search", "Search Name or Location", "")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Map", leafletOutput("map")),
        tabPanel("Table", DTOutput("table")),
        tabPanel("Stats", plotOutput("barplot"))
      )
    )
  )
)

# Server logic
server <- function(input, output) {
  filtered_data <- reactive({
    homicide_data %>%
      filter(year == input$year) %>%
      filter(grepl(input$search, paste(name, location), ignore.case = TRUE))
  })

  output$table <- renderDT({
    datatable(filtered_data())
  })

  output$barplot <- renderPlot({
    data <- filtered_data()
    if ("date" %in% names(data)) {
      data$Month <- month(data$date, label = TRUE)
      bar_data <- data %>% count(Month)
      barplot(bar_data$n, names.arg = bar_data$Month, col = "darkred", main = "Homicides by Month")
    }
  })

  output$map <- renderLeaflet({
    data <- filtered_data()
    if ("longitude" %in% names(data) && "latitude" %in% names(data)) {
      leaflet(data) %>%
        addTiles() %>%
        addMarkers(lng = ~longitude, lat = ~latitude, popup = ~name)
    } else {
      leaflet() %>% addTiles()
    }
  })
}

# Launch the app
shinyApp(ui, server)
