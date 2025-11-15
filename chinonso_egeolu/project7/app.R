# Baltimore City Homicide Dashboard
# Project 7 - R Shiny Implementation

library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(lubridate)
library(DT)
library(plotly)

# Generate sample data (in production, fetch from URLs)
generate_sample_data <- function() {
  set.seed(42)
  
  # Create sample data for 2021-2025
  years <- 2021:2025
  districts <- c("Northern", "Southern", "Eastern", "Western", "Central", 
                 "Northwestern", "Northeastern", "Southwestern", "Southeastern")
  races <- c("Black", "White", "Hispanic", "Asian", "Other")
  causes <- c("Shooting", "Stabbing", "Blunt Force", "Other")
  
  data <- data.frame()
  
  for (year in years) {
    n_records <- sample(80:120, 1)  # Variable records per year
    
    for (i in 1:n_records) {
      month <- sample(1:12, 1)
      day <- sample(1:28, 1)
      date <- as.Date(paste(year, month, day, sep = "-"))
      
      record <- data.frame(
        Date = date,
        Year = year,
        Month = month(date, label = TRUE),
        District = sample(districts, 1),
        Race = sample(races, 1),
        Age = sample(15:70, 1),
        Cause = sample(causes, 1),
        Location = paste("Block", sample(100:900, 1))
      )
      
      data <- rbind(data, record)
    }
  }
  
  return(data)
}

# Load data
homicide_data <- generate_sample_data()

# UI
ui <- dashboardPage(
  skin = "red",
  
  dashboardHeader(title = "Baltimore Homicides 2021-2025"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Trends", tabName = "trends", icon = icon("chart-line")),
      menuItem("Geographic", tabName = "geographic", icon = icon("map")),
      menuItem("Demographics", tabName = "demographics", icon = icon("users")),
      menuItem("Data Table", tabName = "data", icon = icon("table"))
    ),
    
    hr(),
    
    # Filters
    selectInput("year_filter", "Year:", 
                choices = c("All", unique(homicide_data$Year)),
                selected = "All"),
    
    selectInput("district_filter", "District:",
                choices = c("All", unique(homicide_data$District)),
                selected = "All")
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .box-title { font-weight: bold; }
        .small-box { border-radius: 5px; }
        .info-box { border-radius: 5px; }
      "))
    ),
    
    tabItems(
      # Overview Tab
      tabItem(tabName = "overview",
        fluidRow(
          valueBoxOutput("total_homicides"),
          valueBoxOutput("ytd_homicides"),
          valueBoxOutput("change_rate")
        ),
        
        fluidRow(
          box(
            title = "Homicides by Year",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("yearly_chart", height = 300)
          ),
          
          box(
            title = "Top 5 Districts",
            status = "danger",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("district_chart", height = 300)
          )
        ),
        
        fluidRow(
          box(
            title = "Monthly Trend (2024-2025)",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("monthly_trend", height = 300)
          )
        )
      ),
      
      # Trends Tab
      tabItem(tabName = "trends",
        fluidRow(
          box(
            title = "Homicides Over Time",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("time_series", height = 400)
          )
        ),
        
        fluidRow(
          box(
            title = "Seasonal Pattern",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("seasonal_pattern", height = 300)
          ),
          
          box(
            title = "Day of Week Pattern",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("dow_pattern", height = 300)
          )
        )
      ),
      
      # Geographic Tab
      tabItem(tabName = "geographic",
        fluidRow(
          box(
            title = "Homicides by District (All Years)",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("district_map", height = 400)
          )
        ),
        
        fluidRow(
          box(
            title = "Year-over-Year by District",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("district_yoy", height = 400)
          )
        )
      ),
      
      # Demographics Tab
      tabItem(tabName = "demographics",
        fluidRow(
          box(
            title = "Homicides by Race",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("race_chart", height = 300)
          ),
          
          box(
            title = "Homicides by Cause",
            status = "danger",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("cause_chart", height = 300)
          )
        ),
        
        fluidRow(
          box(
            title = "Age Distribution",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("age_dist", height = 300)
          )
        )
      ),
      
      # Data Table Tab
      tabItem(tabName = "data",
        fluidRow(
          box(
            title = "Raw Data",
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
    
    if (input$year_filter != "All") {
      data <- data %>% filter(Year == as.numeric(input$year_filter))
    }
    
    if (input$district_filter != "All") {
      data <- data %>% filter(District == input$district_filter)
    }
    
    return(data)
  })
  
  # Value Boxes
  output$total_homicides <- renderValueBox({
    total <- nrow(filtered_data())
    valueBox(
      value = total,
      subtitle = "Total Homicides",
      icon = icon("skull-crossbones"),
      color = "red"
    )
  })
  
  output$ytd_homicides <- renderValueBox({
    current_year <- year(Sys.Date())
    ytd <- filtered_data() %>% filter(Year == current_year) %>% nrow()
    valueBox(
      value = ytd,
      subtitle = paste(current_year, "YTD"),
      icon = icon("calendar"),
      color = "orange"
    )
  })
  
  output$change_rate <- renderValueBox({
    data <- filtered_data()
    if (nrow(data) > 0 && length(unique(data$Year)) >= 2) {
      years <- sort(unique(data$Year), decreasing = TRUE)
      if (length(years) >= 2) {
        current <- data %>% filter(Year == years[1]) %>% nrow()
        previous <- data %>% filter(Year == years[2]) %>% nrow()
        change <- round(((current - previous) / previous) * 100, 1)
        color <- if (change > 0) "red" else "green"
        icon_name <- if (change > 0) "arrow-up" else "arrow-down"
      } else {
        change <- 0
        color <- "blue"
        icon_name <- "minus"
      }
    } else {
      change <- 0
      color <- "blue"
      icon_name <- "minus"
    }
    
    valueBox(
      value = paste0(change, "%"),
      subtitle = "YoY Change",
      icon = icon(icon_name),
      color = color
    )
  })
  
  # Charts
  output$yearly_chart <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Year) %>%
      summarise(Count = n(), .groups = 'drop')
    
    p <- ggplot(data, aes(x = factor(Year), y = Count)) +
      geom_bar(stat = "identity", fill = "#dd4b39") +
      geom_text(aes(label = Count), vjust = -0.5, size = 4) +
      labs(x = "Year", y = "Homicides") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 0))
    
    ggplotly(p, tooltip = c("x", "y"))
  })
  
  output$district_chart <- renderPlotly({
    data <- filtered_data() %>%
      group_by(District) %>%
      summarise(Count = n(), .groups = 'drop') %>%
      arrange(desc(Count)) %>%
      head(5)
    
    p <- ggplot(data, aes(x = reorder(District, Count), y = Count)) +
      geom_bar(stat = "identity", fill = "#00a65a") +
      coord_flip() +
      labs(x = "", y = "Homicides") +
      theme_minimal()
    
    ggplotly(p, tooltip = c("x", "y"))
  })
  
  output$monthly_trend <- renderPlotly({
    data <- filtered_data() %>%
      filter(Year >= 2024) %>%
      group_by(Year, Month) %>%
      summarise(Count = n(), .groups = 'drop')
    
    p <- ggplot(data, aes(x = Month, y = Count, color = factor(Year), group = Year)) +
      geom_line(size = 1.2) +
      geom_point(size = 2) +
      labs(x = "Month", y = "Homicides", color = "Year") +
      theme_minimal() +
      scale_color_manual(values = c("#dd4b39", "#f39c12"))
    
    ggplotly(p)
  })
  
  output$time_series <- renderPlotly({
    data <- filtered_data() %>%
      mutate(YearMonth = floor_date(Date, "month")) %>%
      group_by(YearMonth) %>%
      summarise(Count = n(), .groups = 'drop')
    
    p <- ggplot(data, aes(x = YearMonth, y = Count)) +
      geom_line(color = "#3c8dbc", size = 1) +
      geom_point(color = "#3c8dbc", size = 2) +
      labs(x = "Date", y = "Homicides") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$seasonal_pattern <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Month) %>%
      summarise(Count = n(), .groups = 'drop')
    
    p <- ggplot(data, aes(x = Month, y = Count)) +
      geom_bar(stat = "identity", fill = "#f39c12") +
      labs(x = "Month", y = "Average Homicides") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  output$dow_pattern <- renderPlotly({
    data <- filtered_data() %>%
      mutate(DayOfWeek = wday(Date, label = TRUE)) %>%
      group_by(DayOfWeek) %>%
      summarise(Count = n(), .groups = 'drop')
    
    p <- ggplot(data, aes(x = DayOfWeek, y = Count)) +
      geom_bar(stat = "identity", fill = "#00a65a") +
      labs(x = "Day of Week", y = "Homicides") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$district_map <- renderPlotly({
    data <- filtered_data() %>%
      group_by(District) %>%
      summarise(Count = n(), .groups = 'drop') %>%
      arrange(desc(Count))
    
    p <- ggplot(data, aes(x = reorder(District, Count), y = Count)) +
      geom_bar(stat = "identity", fill = "#3c8dbc") +
      coord_flip() +
      labs(x = "District", y = "Homicides") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$district_yoy <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Year, District) %>%
      summarise(Count = n(), .groups = 'drop')
    
    p <- ggplot(data, aes(x = factor(Year), y = Count, fill = District)) +
      geom_bar(stat = "identity", position = "dodge") +
      labs(x = "Year", y = "Homicides", fill = "District") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 0))
    
    ggplotly(p)
  })
  
  output$race_chart <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Race) %>%
      summarise(Count = n(), .groups = 'drop')
    
    plot_ly(data, labels = ~Race, values = ~Count, type = 'pie',
            textposition = 'inside',
            textinfo = 'label+percent',
            marker = list(line = list(color = '#FFFFFF', width = 1)))
  })
  
  output$cause_chart <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Cause) %>%
      summarise(Count = n(), .groups = 'drop')
    
    plot_ly(data, labels = ~Cause, values = ~Count, type = 'pie',
            textposition = 'inside',
            textinfo = 'label+percent',
            marker = list(line = list(color = '#FFFFFF', width = 1)))
  })
  
  output$age_dist <- renderPlotly({
    p <- ggplot(filtered_data(), aes(x = Age)) +
      geom_histogram(binwidth = 5, fill = "#3c8dbc", color = "white") +
      labs(x = "Age", y = "Count") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$data_table <- renderDT({
    datatable(
      filtered_data() %>% 
        arrange(desc(Date)) %>%
        select(Date, District, Age, Race, Cause, Location),
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        order = list(list(0, 'desc'))
      ),
      rownames = FALSE,
      filter = 'top'
    )
  })
}

# Run the app
shinyApp(ui = ui, server = server)