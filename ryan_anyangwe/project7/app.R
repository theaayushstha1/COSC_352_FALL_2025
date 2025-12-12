# Baltimore City Homicides Dashboard
library(shiny)
library(shinydashboard)
library(rvest)
library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(DT)
library(plotly)
library(leaflet)
library(stringr)

# Load sample data
homicide_data <- data.frame(
  year = rep(2021:2025, each = 50),
  victim_name = paste("Victim", 1:250),
  age = sample(15:70, 250, replace = TRUE),
  race = sample(c("Black", "White", "Hispanic", "Asian", "Unknown"), 250, replace = TRUE),
  gender = sample(c("Male", "Female", "Unknown"), 250, replace = TRUE),
  cause = sample(c("Shooting", "Stabbing", "Blunt Force", "Other"), 250, replace = TRUE),
  date = sample(seq(as.Date("2021-01-01"), as.Date("2025-12-31"), by = "day"), 250),
  location = paste(sample(100:5000, 250), "Block of", sample(c("North", "South", "East", "West"), 250, replace = TRUE), "Street"),
  district = sample(c("Northern", "Southern", "Eastern", "Western", "Central", "Northeast", "Southwest", "Southeast", "Northwest"), 250, replace = TRUE),
  latitude = runif(250, 39.2, 39.4),
  longitude = runif(250, -76.7, -76.5)
)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Baltimore Homicides (2021-2025)"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Trends", tabName = "trends", icon = icon("chart-line")),
      menuItem("Demographics", tabName = "demographics", icon = icon("users")),
      menuItem("Map", tabName = "map", icon = icon("map")),
      menuItem("Data", tabName = "data", icon = icon("table"))
    ),
    hr(),
    selectInput("year_filter", "Year:", choices = c("All", 2021:2025), selected = "All"),
    selectInput("district_filter", "District:", choices = c("All", unique(homicide_data$district)), selected = "All"),
    actionButton("reset_filters", "Reset")
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "overview",
        fluidRow(
          valueBoxOutput("total", width = 3),
          valueBoxOutput("avg_age", width = 3),
          valueBoxOutput("common_cause", width = 3),
          valueBoxOutput("top_district", width = 3)
        ),
        fluidRow(
          box(title = "By Year", plotlyOutput("year_chart"), width = 6),
          box(title = "By Cause", plotlyOutput("cause_chart"), width = 6)
        )
      ),
      tabItem(tabName = "trends",
        fluidRow(
          box(title = "Monthly Comparison", plotlyOutput("monthly_chart"), width = 12)
        )
      ),
      tabItem(tabName = "demographics",
        fluidRow(
          box(title = "Age", plotlyOutput("age_chart"), width = 6),
          box(title = "Gender", plotlyOutput("gender_chart"), width = 6)
        )
      ),
      tabItem(tabName = "map",
        fluidRow(
          box(title = "Geographic Distribution", leafletOutput("map", height = 600), width = 12)
        )
      ),
      tabItem(tabName = "data",
        fluidRow(
          box(title = "Records", DTOutput("table"), width = 12)
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  filtered_data <- reactive({
    data <- homicide_data
    if (input$year_filter != "All") data <- data %>% filter(year == as.numeric(input$year_filter))
    if (input$district_filter != "All") data <- data %>% filter(district == input$district_filter)
    data
  })
  
  observeEvent(input$reset_filters, {
    updateSelectInput(session, "year_filter", selected = "All")
    updateSelectInput(session, "district_filter", selected = "All")
  })
  
  output$total <- renderValueBox({
    valueBox(nrow(filtered_data()), "Total Homicides", icon = icon("skull-crossbones"), color = "red")
  })
  
  output$avg_age <- renderValueBox({
    valueBox(round(mean(filtered_data()$age), 1), "Avg Age", icon = icon("user"), color = "blue")
  })
  
  output$common_cause <- renderValueBox({
    cause <- filtered_data() %>% count(cause) %>% arrange(desc(n)) %>% slice(1) %>% pull(cause)
    valueBox(cause, "Common Cause", icon = icon("exclamation-triangle"), color = "orange")
  })
  
  output$top_district <- renderValueBox({
    dist <- filtered_data() %>% count(district) %>% arrange(desc(n)) %>% slice(1) %>% pull(district)
    valueBox(dist, "Top District", icon = icon("map-marker"), color = "purple")
  })
  
  output$year_chart <- renderPlotly({
    data <- filtered_data() %>% count(year)
    plot_ly(data, x = ~year, y = ~n, type = 'bar', marker = list(color = '#d9534f'))
  })
  
  output$cause_chart <- renderPlotly({
    data <- filtered_data() %>% count(cause)
    plot_ly(data, labels = ~cause, values = ~n, type = 'pie')
  })
  
  output$monthly_chart <- renderPlotly({
    data <- filtered_data() %>% mutate(month = month(date)) %>% count(year, month) %>% complete(year, month, fill = list(n = 0))
    plot_ly(data, x = ~month, y = ~n, color = ~as.factor(year), type = 'scatter', mode = 'lines+markers')
  })
  
  output$age_chart <- renderPlotly({
    plot_ly(filtered_data(), x = ~age, type = 'histogram', marker = list(color = '#5bc0de'))
  })
  
  output$gender_chart <- renderPlotly({
    data <- filtered_data() %>% count(gender)
    plot_ly(data, labels = ~gender, values = ~n, type = 'pie')
  })
  
  output$map <- renderLeaflet({
    leaflet(filtered_data()) %>% addTiles() %>%
      addCircleMarkers(lng = ~longitude, lat = ~latitude, radius = 5, color = "#d9534f",
                       popup = ~paste0("<b>", victim_name, "</b><br>", date, "<br>", cause))
  })
  
  output$table <- renderDT({
    filtered_data() %>% select(date, victim_name, age, gender, race, cause, district, location) %>%
      datatable(options = list(pageLength = 25))
  })
}

shinyApp(ui = ui, server = server)