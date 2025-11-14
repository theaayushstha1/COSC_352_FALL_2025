# Baltimore City Homicide Dashboard
# R Shiny Application

library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(lubridate)
library(plotly)
library(DT)
library(leaflet)
library(tidyr)

# Load data
load_homicide_data <- function() {
  # In production, this would scrape from the actual URLs
  # For now, we'll create realistic sample data matching the blog structure
  
  set.seed(42)
  
  districts <- c("Central", "Eastern", "Northern", "Northwestern", "Northeastern",
                 "Southern", "Southeastern", "Southwestern", "Western")
  
  neighborhoods <- c("Downtown", "Canton", "Fells Point", "Federal Hill", "Mount Vernon",
                     "Hampden", "Roland Park", "Cherry Hill", "Brooklyn", "Curtis Bay",
                     "Cedonia", "Belair-Edison", "Frankford", "Patterson Park", "Highlandtown")
  
  causes <- c("Shooting", "Stabbing", "Blunt Force", "Asphyxiation", "Unknown")
  
  dispositions <- c("Open/No arrest", "Closed by arrest", "Closed/No prosecution")
  
  races <- c("Black", "White", "Hispanic", "Asian", "Other")
  
  genders <- c("Male", "Female")
  
  # Generate data for each year
  years <- 2021:2025
  all_data <- list()
  
  for (year in years) {
    # Number of homicides varies by year (realistic pattern)
    n_homicides <- case_when(
      year == 2021 ~ 337,
      year == 2022 ~ 333,
      year == 2023 ~ 262,
      year == 2024 ~ 280,
      year == 2025 ~ as.integer(280 * (as.numeric(Sys.Date() - as.Date(paste0(year, "-01-01"))) / 365))
    )
    
    year_data <- data.frame(
      Date = sort(sample(seq(as.Date(paste0(year, "-01-01")), 
                             as.Date(paste0(year, "-12-31")), 
                             by = "day"), 
                         n_homicides, replace = TRUE)),
      District = sample(districts, n_homicides, replace = TRUE, 
                       prob = c(0.15, 0.14, 0.10, 0.12, 0.11, 0.10, 0.12, 0.08, 0.08)),
      Neighborhood = sample(neighborhoods, n_homicides, replace = TRUE),
      Age = sample(c(15:75, NA), n_homicides, replace = TRUE, 
                   prob = c(rep(0.01, 5), rep(0.03, 15), rep(0.02, 20), rep(0.01, 21), rep(0.005, 5))),
      Gender = sample(genders, n_homicides, replace = TRUE, prob = c(0.88, 0.12)),
      Race = sample(races, n_homicides, replace = TRUE, prob = c(0.85, 0.08, 0.04, 0.02, 0.01)),
      Cause = sample(causes, n_homicides, replace = TRUE, prob = c(0.85, 0.08, 0.03, 0.02, 0.02)),
      Disposition = sample(dispositions, n_homicides, replace = TRUE),
      Year = year
    )
    
    # Add time of day
    year_data$Hour <- sample(0:23, n_homicides, replace = TRUE, 
                             prob = c(rep(3, 6), rep(1, 6), rep(2, 6), rep(4, 6)))
    
    # Add lat/lon (Baltimore City approximate bounds)
    year_data$Latitude <- runif(n_homicides, 39.197, 39.372)
    year_data$Longitude <- runif(n_homicides, -76.711, -76.529)
    
    all_data[[as.character(year)]] <- year_data
  }
  
  combined_data <- bind_rows(all_data)
  combined_data$Month <- month(combined_data$Date, label = TRUE)
  combined_data$Weekday <- wday(combined_data$Date, label = TRUE)
  combined_data$IsWeekend <- combined_data$Weekday %in% c("Sat", "Sun")
  
  return(combined_data)
}

# Load data at startup
homicide_data <- load_homicide_data()

# UI
ui <- dashboardPage(
  skin = "red",
  
  dashboardHeader(title = "Baltimore Homicide Analysis 2021-2025"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Trends", tabName = "trends", icon = icon("chart-line")),
      menuItem("Districts", tabName = "districts", icon = icon("map")),
      menuItem("Demographics", tabName = "demographics", icon = icon("users")),
      menuItem("Time Analysis", tabName = "time", icon = icon("clock")),
      menuItem("Map", tabName = "map", icon = icon("map-marked-alt")),
      menuItem("Data Table", tabName = "data", icon = icon("table"))
    ),
    
    hr(),
    
    selectInput("year_filter", "Filter by Year:",
                choices = c("All Years", 2021:2025),
                selected = "All Years"),
    
    selectInput("district_filter", "Filter by District:",
                choices = c("All Districts", unique(homicide_data$District)),
                selected = "All Districts")
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .info-box { min-height: 90px; }
        .info-box-icon { height: 90px; line-height: 90px; }
        .info-box-content { padding: 5px 10px; }
      "))
    ),
    
    tabItems(
      # Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                valueBoxOutput("total_homicides", width = 3),
                valueBoxOutput("avg_per_year", width = 3),
                valueBoxOutput("clearance_rate", width = 3),
                valueBoxOutput("ytd_change", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Homicides by Year",
                  status = "danger",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("yearly_trend_plot", height = 300)
                ),
                
                box(
                  title = "Top 5 Districts",
                  status = "danger",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("top_districts_plot", height = 300)
                )
              ),
              
              fluidRow(
                box(
                  title = "Monthly Pattern (All Years)",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("monthly_pattern_plot", height = 300)
                ),
                
                box(
                  title = "Day of Week Distribution",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("weekday_plot", height = 300)
                )
              )
      ),
      
      # Trends Tab
      tabItem(tabName = "trends",
              fluidRow(
                box(
                  title = "Cumulative Homicides by Year",
                  status = "danger",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("cumulative_plot", height = 400)
                )
              ),
              
              fluidRow(
                box(
                  title = "Monthly Trends Comparison",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("monthly_comparison_plot", height = 400)
                )
              )
      ),
      
      # Districts Tab
      tabItem(tabName = "districts",
              fluidRow(
                box(
                  title = "Homicides by District",
                  status = "danger",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("district_bar_plot", height = 400)
                ),
                
                box(
                  title = "District Clearance Rates",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("district_clearance_plot", height = 400)
                )
              ),
              
              fluidRow(
                box(
                  title = "District Heatmap (Year x District)",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("district_heatmap", height = 400)
                )
              )
      ),
      
      # Demographics Tab
      tabItem(tabName = "demographics",
              fluidRow(
                box(
                  title = "Age Distribution",
                  status = "danger",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("age_distribution_plot", height = 300)
                ),
                
                box(
                  title = "Gender Distribution",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("gender_plot", height = 300)
                )
              ),
              
              fluidRow(
                box(
                  title = "Race Distribution",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("race_plot", height = 300)
                ),
                
                box(
                  title = "Cause of Death",
                  status = "danger",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("cause_plot", height = 300)
                )
              )
      ),
      
      # Time Analysis Tab
      tabItem(tabName = "time",
              fluidRow(
                box(
                  title = "Homicides by Hour of Day",
                  status = "danger",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("hourly_plot", height = 400)
                )
              ),
              
              fluidRow(
                box(
                  title = "Weekend vs Weekday by Hour",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("weekend_hourly_plot", height = 400)
                )
              )
      ),
      
      # Map Tab
      tabItem(tabName = "map",
              fluidRow(
                box(
                  title = "Homicide Locations",
                  status = "danger",
                  solidHeader = TRUE,
                  width = 12,
                  leafletOutput("homicide_map", height = 600)
                )
              )
      ),
      
      # Data Table Tab
      tabItem(tabName = "data",
              fluidRow(
                box(
                  title = "Homicide Data",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("data_table")
                )
              )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive filtered data
  filtered_data <- reactive({
    data <- homicide_data
    
    if (input$year_filter != "All Years") {
      data <- data %>% filter(Year == as.numeric(input$year_filter))
    }
    
    if (input$district_filter != "All Districts") {
      data <- data %>% filter(District == input$district_filter)
    }
    
    return(data)
  })
  
  # Value Boxes
  output$total_homicides <- renderValueBox({
    valueBox(
      nrow(filtered_data()),
      "Total Homicides",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  output$avg_per_year <- renderValueBox({
    data <- filtered_data()
    years_count <- length(unique(data$Year))
    avg <- round(nrow(data) / years_count, 1)
    
    valueBox(
      avg,
      "Average per Year",
      icon = icon("chart-line"),
      color = "orange"
    )
  })
  
  output$clearance_rate <- renderValueBox({
    data <- filtered_data()
    closed <- sum(grepl("Closed|arrest", data$Disposition, ignore.case = TRUE))
    rate <- round((closed / nrow(data)) * 100, 1)
    
    valueBox(
      paste0(rate, "%"),
      "Clearance Rate",
      icon = icon("check-circle"),
      color = "green"
    )
  })
  
  output$ytd_change <- renderValueBox({
    current_year <- year(Sys.Date())
    current_ytd <- homicide_data %>%
      filter(Year == current_year, Date <= Sys.Date()) %>%
      nrow()
    
    last_year_ytd <- homicide_data %>%
      filter(Year == current_year - 1, Date <= (Sys.Date() - years(1))) %>%
      nrow()
    
    change <- current_ytd - last_year_ytd
    pct_change <- round((change / last_year_ytd) * 100, 1)
    
    color <- ifelse(change > 0, "red", "green")
    icon_name <- ifelse(change > 0, "arrow-up", "arrow-down")
    
    valueBox(
      paste0(ifelse(change > 0, "+", ""), change, " (", pct_change, "%)"),
      "YTD Change vs Last Year",
      icon = icon(icon_name),
      color = color
    )
  })
  
  # Yearly Trend Plot
  output$yearly_trend_plot <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Year) %>%
      summarise(Count = n())
    
    plot_ly(data, x = ~Year, y = ~Count, type = 'bar',
            marker = list(color = '#d9534f')) %>%
      layout(xaxis = list(title = "Year"),
             yaxis = list(title = "Number of Homicides"),
             hovermode = "closest")
  })
  
  # Top Districts Plot
  output$top_districts_plot <- renderPlotly({
    data <- filtered_data() %>%
      group_by(District) %>%
      summarise(Count = n()) %>%
      arrange(desc(Count)) %>%
      head(5)
    
    plot_ly(data, x = ~reorder(District, Count), y = ~Count, type = 'bar',
            marker = list(color = '#f0ad4e')) %>%
      layout(xaxis = list(title = "District"),
             yaxis = list(title = "Number of Homicides"),
             hovermode = "closest")
  })
  
  # Monthly Pattern Plot
  output$monthly_pattern_plot <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Month) %>%
      summarise(Count = n())
    
    plot_ly(data, x = ~Month, y = ~Count, type = 'scatter', mode = 'lines+markers',
            line = list(color = '#5cb85c', width = 3),
            marker = list(size = 8, color = '#5cb85c')) %>%
      layout(xaxis = list(title = "Month"),
             yaxis = list(title = "Number of Homicides"),
             hovermode = "closest")
  })
  
  # Weekday Plot
  output$weekday_plot <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Weekday) %>%
      summarise(Count = n())
    
    plot_ly(data, labels = ~Weekday, values = ~Count, type = 'pie',
            marker = list(colors = c('#d9534f', '#f0ad4e', '#5bc0de', '#5cb85c', 
                                     '#0275d8', '#f7931e', '#c71585'))) %>%
      layout(showlegend = TRUE)
  })
  
  # Cumulative Plot
  output$cumulative_plot <- renderPlotly({
    data <- filtered_data() %>%
      mutate(DayOfYear = yday(Date)) %>%
      group_by(Year, DayOfYear) %>%
      summarise(Count = n(), .groups = 'drop') %>%
      group_by(Year) %>%
      arrange(DayOfYear) %>%
      mutate(Cumulative = cumsum(Count))
    
    plot_ly(data, x = ~DayOfYear, y = ~Cumulative, color = ~as.factor(Year),
            type = 'scatter', mode = 'lines', colors = 'Set1') %>%
      layout(xaxis = list(title = "Day of Year"),
             yaxis = list(title = "Cumulative Homicides"),
             hovermode = "closest",
             legend = list(title = list(text = "Year")))
  })
  
  # Monthly Comparison Plot
  output$monthly_comparison_plot <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Year, Month) %>%
      summarise(Count = n(), .groups = 'drop')
    
    plot_ly(data, x = ~Month, y = ~Count, color = ~as.factor(Year),
            type = 'scatter', mode = 'lines+markers', colors = 'Set1') %>%
      layout(xaxis = list(title = "Month"),
             yaxis = list(title = "Number of Homicides"),
             hovermode = "closest",
             legend = list(title = list(text = "Year")))
  })
  
  # District Bar Plot
  output$district_bar_plot <- renderPlotly({
    data <- filtered_data() %>%
      group_by(District) %>%
      summarise(Count = n()) %>%
      arrange(desc(Count))
    
    plot_ly(data, y = ~reorder(District, Count), x = ~Count, type = 'bar',
            orientation = 'h', marker = list(color = '#d9534f')) %>%
      layout(yaxis = list(title = "District"),
             xaxis = list(title = "Number of Homicides"),
             hovermode = "closest")
  })
  
  # District Clearance Plot
  output$district_clearance_plot <- renderPlotly({
    data <- filtered_data() %>%
      group_by(District) %>%
      summarise(
        Total = n(),
        Closed = sum(grepl("Closed|arrest", Disposition, ignore.case = TRUE)),
        ClearanceRate = (Closed / Total) * 100
      ) %>%
      arrange(desc(ClearanceRate))
    
    plot_ly(data, y = ~reorder(District, ClearanceRate), x = ~ClearanceRate,
            type = 'bar', orientation = 'h', marker = list(color = '#5bc0de')) %>%
      layout(yaxis = list(title = "District"),
             xaxis = list(title = "Clearance Rate (%)"),
             hovermode = "closest")
  })
  
  # District Heatmap
  output$district_heatmap <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Year, District) %>%
      summarise(Count = n(), .groups = 'drop') %>%
      pivot_wider(names_from = Year, values_from = Count, values_fill = 0)
    
    mat <- as.matrix(data[, -1])
    rownames(mat) <- data$District
    
    plot_ly(z = mat, x = colnames(mat), y = rownames(mat),
            type = "heatmap", colorscale = "Reds") %>%
      layout(xaxis = list(title = "Year"),
             yaxis = list(title = "District"))
  })
  
  # Age Distribution Plot
  output$age_distribution_plot <- renderPlotly({
    data <- filtered_data() %>%
      filter(!is.na(Age))
    
    plot_ly(data, x = ~Age, type = 'histogram', nbinsx = 30,
            marker = list(color = '#d9534f', line = list(color = 'white', width = 1))) %>%
      layout(xaxis = list(title = "Age"),
             yaxis = list(title = "Number of Homicides"),
             hovermode = "closest")
  })
  
  # Gender Plot
  output$gender_plot <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Gender) %>%
      summarise(Count = n())
    
    plot_ly(data, labels = ~Gender, values = ~Count, type = 'pie',
            marker = list(colors = c('#5bc0de', '#f0ad4e'))) %>%
      layout(showlegend = TRUE)
  })
  
  # Race Plot
  output$race_plot <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Race) %>%
      summarise(Count = n()) %>%
      arrange(desc(Count))
    
    plot_ly(data, x = ~reorder(Race, Count), y = ~Count, type = 'bar',
            marker = list(color = '#f0ad4e')) %>%
      layout(xaxis = list(title = "Race"),
             yaxis = list(title = "Number of Homicides"),
             hovermode = "closest")
  })
  
  # Cause Plot
  output$cause_plot <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Cause) %>%
      summarise(Count = n()) %>%
      arrange(desc(Count))
    
    plot_ly(data, labels = ~Cause, values = ~Count, type = 'pie') %>%
      layout(showlegend = TRUE)
  })
  
  # Hourly Plot
  output$hourly_plot <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Hour) %>%
      summarise(Count = n())
    
    plot_ly(data, x = ~Hour, y = ~Count, type = 'bar',
            marker = list(color = '#d9534f')) %>%
      layout(xaxis = list(title = "Hour of Day", dtick = 1),
             yaxis = list(title = "Number of Homicides"),
             hovermode = "closest")
  })
  
  # Weekend Hourly Plot
  output$weekend_hourly_plot <- renderPlotly({
    data <- filtered_data() %>%
      mutate(DayType = ifelse(IsWeekend, "Weekend", "Weekday")) %>%
      group_by(Hour, DayType) %>%
      summarise(Count = n(), .groups = 'drop')
    
    plot_ly(data, x = ~Hour, y = ~Count, color = ~DayType,
            type = 'scatter', mode = 'lines+markers',
            colors = c('#5bc0de', '#f0ad4e')) %>%
      layout(xaxis = list(title = "Hour of Day", dtick = 1),
             yaxis = list(title = "Number of Homicides"),
             hovermode = "closest",
             legend = list(title = list(text = "Day Type")))
  })
  
  # Map
  output$homicide_map <- renderLeaflet({
    data <- filtered_data()
    
    leaflet(data) %>%
      addTiles() %>%
      addCircleMarkers(
        lng = ~Longitude,
        lat = ~Latitude,
        radius = 4,
        color = "#d9534f",
        fillOpacity = 0.6,
        popup = ~paste0(
          "<b>Date:</b> ", Date, "<br>",
          "<b>District:</b> ", District, "<br>",
          "<b>Neighborhood:</b> ", Neighborhood, "<br>",
          "<b>Age:</b> ", ifelse(is.na(Age), "Unknown", Age), "<br>",
          "<b>Gender:</b> ", Gender, "<br>",
          "<b>Cause:</b> ", Cause
        ),
        clusterOptions = markerClusterOptions()
      ) %>%
      setView(lng = -76.6122, lat = 39.2904, zoom = 11)
  })
  
  # Data Table
  output$data_table <- renderDT({
    data <- filtered_data() %>%
      select(Date, District, Neighborhood, Age, Gender, Race, Cause, Disposition) %>%
      arrange(desc(Date))
    
    datatable(data, 
              options = list(pageLength = 25, scrollX = TRUE),
              filter = 'top',
              rownames = FALSE)
  })
}

# Run the application
shinyApp(ui = ui, server = server)
