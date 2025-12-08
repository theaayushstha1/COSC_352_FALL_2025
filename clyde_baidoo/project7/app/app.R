library(shiny)
library(dplyr)
library(ggplot2)
library(plotly)
library(DT)
library(lubridate)
library(rvest)
library(stringr)
library(tidygeocoder)
library(leaflet)

# UI
ui <- fluidPage(
  titlePanel("Baltimore Homicides"),
  sidebarLayout(
    sidebarPanel(
      helpText("Filter and view homicide data.")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Table", DTOutput("table")),
        tabPanel("Map", leafletOutput("map"))
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  # Reactive placeholder data
  df <- reactive({
    data.frame(Date = Sys.Date(), Name = "Example", Address = "Baltimore")
  })
  
  output$table <- renderDT({
    df()
  })
  
  output$map <- renderLeaflet({
    leaflet() %>% addTiles() %>%
      addMarkers(lng = -76.61, lat = 39.29, popup = "Baltimore")
  })
}

shinyApp(ui, server)
