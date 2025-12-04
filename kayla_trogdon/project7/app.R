library(shiny)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(lubridate)
library(DT)
library(plotly)

# Load and prepare data
homicides <- read.csv("baltimore_homicides_2021_2025.csv", stringsAsFactors = FALSE)

# Data preprocessing
homicides$DateDied <- mdy(homicides$Date.Died)
homicides$Year <- as.character(homicides$Year)
homicides$Age <- as.numeric(homicides$Age)
homicides$Month <- month(homicides$DateDied, label = TRUE, abbr = FALSE)
homicides$MonthNum <- month(homicides$DateDied)

# Clean up case closed field
homicides$Case.Closed <- ifelse(homicides$Case.Closed == "Closed" | homicides$Case.Closed == "Clsoed", 
                                "Closed", "Open")

# UI Definition
ui <- dashboardPage(
  skin = "red",
  
  # Header
  dashboardHeader(title = "Baltimore Homicides 2021-2025"),
  
  # Sidebar
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Time Trends", tabName = "time", icon = icon("chart-line")),
      menuItem("Locations", tabName = "locations", icon = icon("map-marker-alt")),
      menuItem("Demographics", tabName = "demographics", icon = icon("users")),
      menuItem("Data Explorer", tabName = "data", icon = icon("table"))
    ),
    
    # Filters
    hr(),
    h4("Filters", style = "padding-left: 15px;"),
    
    selectInput("filterYear", "Year:",
                choices = c("All", sort(unique(homicides$Year))),
                selected = "All"),
    
    selectInput("filterMonth", "Month:",
                choices = c("All", month.name),
                selected = "All")
  ),
  
  # Body
  dashboardBody(
    tabItems(
      
      # Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                valueBoxOutput("totalHomicides", width = 3),
                valueBoxOutput("totalLocations", width = 3),
                valueBoxOutput("avgAge", width = 3),
                valueBoxOutput("closureRate", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Homicides by Year", 
                  status = "danger", 
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("overviewYearly")
                ),
                box(
                  title = "Homicides by Month (All Years)", 
                  status = "warning", 
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("overviewMonthly")
                )
              ),
              
              fluidRow(
                box(
                  title = "Top 10 Dangerous Locations", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("overviewTopLocations")
                )
              )
      ),
      
      # Time Trends Tab
      tabItem(tabName = "time",
              fluidRow(
                box(
                  title = "Yearly Trend Analysis", 
                  status = "danger", 
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("timeYearlyTrend", height = 400)
                )
              ),
              
              fluidRow(
                box(
                  title = "Monthly Distribution by Year", 
                  status = "warning", 
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("timeMonthlyByYear", height = 400)
                )
              ),
              
              fluidRow(
                box(
                  title = "Cumulative Homicides Over Time", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("timeCumulative", height = 400)
                )
              )
      ),
      
      # Locations Tab
      tabItem(tabName = "locations",
              fluidRow(
                box(
                  title = "Top 20 Most Dangerous Address Blocks", 
                  status = "danger", 
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("locationsTop20", height = 600)
                )
              ),
              
              fluidRow(
                box(
                  title = "Locations with Multiple Homicides", 
                  status = "warning", 
                  solidHeader = TRUE,
                  width = 6,
                  plotOutput("locationsRepeat")
                ),
                box(
                  title = "Case Closure by Location Type", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("locationsClosure")
                )
              )
      ),
      
      # Demographics Tab
      tabItem(tabName = "demographics",
              fluidRow(
                box(
                  title = "Age Distribution of Victims", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("demoAgeDistribution")
                ),
                box(
                  title = "Age Distribution by Year", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("demoAgeByYear")
                )
              ),
              
              fluidRow(
                box(
                  title = "Case Closure Status", 
                  status = "success", 
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("demoCaseClosure")
                ),
                box(
                  title = "Surveillance Camera Availability", 
                  status = "warning", 
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("demoSurveillance")
                )
              )
      ),
      
      # Data Explorer Tab
      tabItem(tabName = "data",
              fluidRow(
                box(
                  title = "Full Homicide Dataset", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("dataTable")
                )
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive filtered data
  filtered_data <- reactive({
    data <- homicides
    
    if (input$filterYear != "All") {
      data <- data %>% filter(Year == input$filterYear)
    }
    
    if (input$filterMonth != "All") {
      data <- data %>% filter(Month == input$filterMonth)
    }
    
    return(data)
  })
  
  # Value Boxes
  output$totalHomicides <- renderValueBox({
    valueBox(
      nrow(filtered_data()),
      "Total Homicides",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  output$totalLocations <- renderValueBox({
    valueBox(
      length(unique(filtered_data()$Address.Block.Found)),
      "Unique Locations",
      icon = icon("map-marker-alt"),
      color = "yellow"
    )
  })
  
  output$avgAge <- renderValueBox({
    valueBox(
      round(mean(filtered_data()$Age, na.rm = TRUE), 1),
      "Average Age",
      icon = icon("user"),
      color = "blue"
    )
  })
  
  output$closureRate <- renderValueBox({
    closed_count <- sum(filtered_data()$Case.Closed == "Closed", na.rm = TRUE)
    total_count <- nrow(filtered_data())
    rate <- ifelse(total_count > 0, round((closed_count / total_count) * 100, 1), 0)
    
    valueBox(
      paste0(rate, "%"),
      "Case Closure Rate",
      icon = icon("gavel"),
      color = "green"
    )
  })
  
  # Overview Charts
  output$overviewYearly <- renderPlotly({
    yearly_data <- filtered_data() %>%
      group_by(Year) %>%
      summarise(Count = n())
    
    plot_ly(yearly_data, x = ~Year, y = ~Count, type = 'bar',
            marker = list(color = '#d9534f')) %>%
      layout(title = "",
             xaxis = list(title = "Year"),
             yaxis = list(title = "Number of Homicides"))
  })
  
  output$overviewMonthly <- renderPlotly({
    monthly_data <- filtered_data() %>%
      group_by(Month) %>%
      summarise(Count = n()) %>%
      arrange(match(Month, month.name))
    
    plot_ly(monthly_data, x = ~Month, y = ~Count, type = 'bar',
            marker = list(color = '#f0ad4e')) %>%
      layout(title = "",
             xaxis = list(title = "Month"),
             yaxis = list(title = "Number of Homicides"))
  })
  
  output$overviewTopLocations <- renderPlotly({
    top_locations <- filtered_data() %>%
      count(Address.Block.Found) %>%
      arrange(desc(n)) %>%
      head(10)
    
    plot_ly(top_locations, x = ~n, y = ~reorder(Address.Block.Found, n), 
            type = 'bar', orientation = 'h',
            marker = list(color = '#5bc0de')) %>%
      layout(title = "",
             xaxis = list(title = "Number of Homicides"),
             yaxis = list(title = ""))
  })
  
  # Time Trends Charts
  output$timeYearlyTrend <- renderPlotly({
    yearly_data <- homicides %>%
      group_by(Year) %>%
      summarise(Count = n())
    
    plot_ly(yearly_data, x = ~Year, y = ~Count, type = 'scatter', mode = 'lines+markers',
            line = list(color = '#d9534f', width = 3),
            marker = list(size = 10)) %>%
      layout(title = "Homicides by Year (2021-2025)",
             xaxis = list(title = "Year"),
             yaxis = list(title = "Number of Homicides"))
  })
  
  output$timeMonthlyByYear <- renderPlotly({
    monthly_by_year <- homicides %>%
      group_by(Year, Month) %>%
      summarise(Count = n(), .groups = 'drop')
    
    plot_ly(monthly_by_year, x = ~Month, y = ~Count, color = ~Year, type = 'scatter', mode = 'lines+markers') %>%
      layout(title = "Monthly Homicides by Year",
             xaxis = list(title = "Month"),
             yaxis = list(title = "Number of Homicides"))
  })
  
  output$timeCumulative <- renderPlotly({
    cumulative_data <- homicides %>%
      arrange(DateDied) %>%
      mutate(Cumulative = row_number())
    
    plot_ly(cumulative_data, x = ~DateDied, y = ~Cumulative, type = 'scatter', mode = 'lines',
            line = list(color = '#5bc0de', width = 2)) %>%
      layout(title = "Cumulative Homicides Over Time",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Cumulative Count"))
  })
  
  # Locations Charts
  output$locationsTop20 <- renderPlotly({
    top_20 <- filtered_data() %>%
      count(Address.Block.Found) %>%
      arrange(desc(n)) %>%
      head(20)
    
    plot_ly(top_20, x = ~n, y = ~reorder(Address.Block.Found, n), 
            type = 'bar', orientation = 'h',
            marker = list(color = '#d9534f')) %>%
      layout(title = "",
             xaxis = list(title = "Number of Homicides"),
             yaxis = list(title = "Address Block"))
  })
  
  output$locationsRepeat <- renderPlot({
    repeat_locations <- filtered_data() %>%
      count(Address.Block.Found) %>%
      count(n, name = "Locations") %>%
      rename(Homicides = n)
    
    ggplot(repeat_locations, aes(x = as.factor(Homicides), y = Locations)) +
      geom_bar(stat = "identity", fill = "#f0ad4e") +
      labs(title = "",
           x = "Number of Homicides at Location",
           y = "Number of Locations") +
      theme_minimal() +
      theme(text = element_text(size = 12))
  })
  
  output$locationsClosure <- renderPlotly({
    closure_data <- filtered_data() %>%
      filter(Case.Closed != "") %>%
      group_by(Case.Closed) %>%
      summarise(Count = n())
    
    plot_ly(closure_data, labels = ~Case.Closed, values = ~Count, type = 'pie',
            marker = list(colors = c('#5cb85c', '#d9534f'))) %>%
      layout(title = "")
  })
  
  # Demographics Charts
  output$demoAgeDistribution <- renderPlotly({
    plot_ly(filtered_data(), x = ~Age, type = 'histogram', nbinsx = 30,
            marker = list(color = '#5bc0de')) %>%
      layout(title = "",
             xaxis = list(title = "Age"),
             yaxis = list(title = "Count"))
  })
  
  output$demoAgeByYear <- renderPlotly({
    plot_ly(filtered_data(), x = ~Year, y = ~Age, type = 'box',
            marker = list(color = '#f0ad4e')) %>%
      layout(title = "",
             xaxis = list(title = "Year"),
             yaxis = list(title = "Age"))
  })
  
  output$demoCaseClosure <- renderPlotly({
    closure_data <- filtered_data() %>%
      filter(Case.Closed != "") %>%
      count(Case.Closed)
    
    plot_ly(closure_data, labels = ~Case.Closed, values = ~n, type = 'pie',
            marker = list(colors = c('#5cb85c', '#d9534f'))) %>%
      layout(title = "")
  })
  
  output$demoSurveillance <- renderPlotly({
    surveillance_data <- filtered_data() %>%
      mutate(HasCamera = ifelse(grepl("camera", Surveillance.Camera, ignore.case = TRUE), "Yes", "No/Unknown")) %>%
      count(HasCamera)
    
    plot_ly(surveillance_data, labels = ~HasCamera, values = ~n, type = 'pie',
            marker = list(colors = c('#d9534f', '#f0ad4e'))) %>%
      layout(title = "")
  })
  
  # Data Table
  output$dataTable <- renderDT({
    datatable(filtered_data() %>% 
                select(Year, Date.Died, Name, Age, Address.Block.Found, Notes, Case.Closed),
              options = list(pageLength = 25, scrollX = TRUE),
              filter = 'top',
              rownames = FALSE)
  })
}

# Run the app
shinyApp(ui = ui, server = server)