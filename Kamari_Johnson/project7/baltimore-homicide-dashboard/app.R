library(shiny)
library(shinydashboard)
library(leaflet)
library(DT)
library(ggplot2)
library(dplyr)
library(tibble)
library(shinycssloaders)  # Optional: for loading spinners

source("R/data_processing.R")

ui <- dashboardPage(
  dashboardHeader(title = "Baltimore Homicides"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview"),
      menuItem("Map", tabName = "map"),
      menuItem("Table", tabName = "table")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem("overview", withSpinner(plotOutput("trendPlot"))),
      tabItem("map", withSpinner(leafletOutput("homicideMap"))),
      tabItem("table", withSpinner(DTOutput("homicideTable")))
    )
  )
)

server <- function(input, output) {
  data <- tryCatch({
    load_all_years()
  }, error = function(e) {
    message("Error loading data: ", e$message)
    data.frame(Name = "Test", Age = 30, Year = 2025)
  })

  output$trendPlot <- renderPlot({
    data %>%
      count(Year) %>%
      ggplot(aes(x = Year, y = n)) +
      geom_col(fill = "darkred") +
      labs(title = "Homicides per Year", x = "Year", y = "Count") +
      theme_minimal()
  })

  output$homicideMap <- renderLeaflet({
    leaflet(data) %>%
      addTiles() %>%
      addCircleMarkers(
        ~runif(nrow(data), 39.25, 39.35),
        ~runif(nrow(data), -76.65, -76.55),
        popup = ~paste(Name, Age),
        radius = 4
      )
  })

  output$homicideTable <- renderDT({
    datatable(data)
  })
}

shinyApp(ui, server)