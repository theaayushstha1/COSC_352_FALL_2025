library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(tidyr)
library(lubridate)
library(plotly)
library(DT)

# Load data with error handling
tryCatch({
  homicide_data <- read.csv("homicide_data.csv", stringsAsFactors = FALSE)
  
  if (nrow(homicide_data) == 0) {
    stop("No data in CSV file")
  }
  
  # Data preprocessing with better error handling
  homicide_data <- homicide_data %>%
    mutate(
      # Try multiple date formats
      Date = as.Date(DateDied, format = "%m/%d/%y"),
      # If year is parsed as 2000s instead of 2020s, fix it
      Year = as.integer(Year),
      Year = ifelse(!is.na(Year) & Year < 100, Year + 2000, Year),
      Year = ifelse(!is.na(Date), year(Date), Year),
      Month = ifelse(!is.na(Date), month(Date, label = TRUE), NA),
      Age = suppressWarnings(as.numeric(Age)),
      HasCamera = !is.na(SurveillanceCamera) & 
                  SurveillanceCamera != "" & 
                  tolower(SurveillanceCamera) != "none",
      IsClosed = !is.na(CaseClosed) & 
                 CaseClosed != "" &
                 tolower(CaseClosed) == "closed"
    )
  
  # Filter for valid dates
  homicide_data <- homicide_data %>%
    filter(!is.na(Date))
  
  # Ensure Year is in correct range (2021-2025)
  if (any(!is.na(homicide_data$Year) & homicide_data$Year >= 2021 & homicide_data$Year <= 2025)) {
    homicide_data <- homicide_data %>%
      filter(Year >= 2021 & Year <= 2025)
  }
  
}, error = function(e) {
  cat("ERROR loading data:", e$message, "\n")
  stop("Failed to load homicide data")
})

ui <- dashboardPage(
  skin = "red",
  dashboardHeader(title = "Baltimore Homicides 2021-2025"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Temporal", tabName = "temporal", icon = icon("chart-line")),
      menuItem("Cameras", tabName = "cameras", icon = icon("video")),
      menuItem("Demographics", tabName = "demographics", icon = icon("users")),
      menuItem("Cases", tabName = "cases", icon = icon("gavel")),
      menuItem("Data Table", tabName = "datatable", icon = icon("table"))
    ),
    hr(),
    selectInput("yearFilter", "Filter by Year:", 
                choices = c("All Years", sort(unique(homicide_data$Year))),
                selected = "All Years")
  ),
  
  dashboardBody(
    tabItems(
      tabItem(tabName = "overview",
        fluidRow(
          valueBoxOutput("totalHomicides", width = 3),
          valueBoxOutput("closureRate", width = 3),
          valueBoxOutput("avgAge", width = 3),
          valueBoxOutput("cameraRate", width = 3)
        ),
        fluidRow(
          box(title = "Homicides by Year", status = "danger", solidHeader = TRUE, width = 6,
              plotlyOutput("yearlyTrend", height = 300)),
          box(title = "Monthly Distribution", status = "danger", solidHeader = TRUE, width = 6,
              plotlyOutput("monthlyDist", height = 300))
        ),
        fluidRow(
          box(title = "Top 10 Deadliest Locations", status = "danger", solidHeader = TRUE, width = 12,
              plotlyOutput("topLocations", height = 350))
        )
      ),
      
      tabItem(tabName = "temporal",
        fluidRow(
          box(title = "Homicides Over Time", status = "danger", solidHeader = TRUE, width = 12,
              plotlyOutput("timeSeriesPlot", height = 400))
        ),
        fluidRow(
          box(title = "Day of Week", status = "danger", solidHeader = TRUE, width = 6,
              plotlyOutput("dayOfWeekPlot", height = 300)),
          box(title = "Heatmap", status = "danger", solidHeader = TRUE, width = 6,
              plotlyOutput("heatmapPlot", height = 300))
        )
      ),
      
      tabItem(tabName = "cameras",
        fluidRow(
          box(title = "Camera Impact on Closure Rates", status = "danger", solidHeader = TRUE, width = 12,
              plotlyOutput("cameraClosureRate", height = 300))
        ),
        fluidRow(
          box(title = "Camera Presence by Year", status = "danger", solidHeader = TRUE, width = 6,
              plotlyOutput("cameraByYear", height = 300)),
          box(title = "Closure Rate Comparison", status = "danger", solidHeader = TRUE, width = 6,
              plotlyOutput("closureComparison", height = 300))
        )
      ),
      
      tabItem(tabName = "demographics",
        fluidRow(
          box(title = "Age Distribution", status = "danger", solidHeader = TRUE, width = 6,
              plotlyOutput("ageDistribution", height = 350)),
          box(title = "Average Age by Year", status = "danger", solidHeader = TRUE, width = 6,
              plotlyOutput("ageByYear", height = 350))
        ),
        fluidRow(
          box(title = "Age by Month", status = "danger", solidHeader = TRUE, width = 12,
              plotlyOutput("ageByMonth", height = 350))
        )
      ),
      
      tabItem(tabName = "cases",
        fluidRow(
          box(title = "Case Status", status = "danger", solidHeader = TRUE, width = 6,
              plotlyOutput("caseStatusPie", height = 350)),
          box(title = "Closure Rate by Year", status = "danger", solidHeader = TRUE, width = 6,
              plotlyOutput("closureByYear", height = 350))
        ),
        fluidRow(
          box(title = "Closure Timeline", status = "danger", solidHeader = TRUE, width = 12,
              plotlyOutput("closureTimeline", height = 350))
        )
      ),
      
      tabItem(tabName = "datatable",
        fluidRow(
          box(title = "All Records", status = "danger", solidHeader = TRUE, width = 12,
              DTOutput("dataTable"))
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  filtered_data <- reactive({
    data <- homicide_data
    if (input$yearFilter != "All Years") {
      data <- data %>% filter(Year == as.numeric(input$yearFilter))
    }
    data
  })
  
  output$totalHomicides <- renderValueBox({
    valueBox(nrow(filtered_data()), "Total Homicides", icon = icon("exclamation-triangle"), color = "red")
  })
  
  output$closureRate <- renderValueBox({
    rate <- mean(filtered_data()$IsClosed, na.rm = TRUE) * 100
    valueBox(paste0(round(rate, 1), "%"), "Closure Rate", icon = icon("check-circle"), color = "yellow")
  })
  
  output$avgAge <- renderValueBox({
    valueBox(round(mean(filtered_data()$Age, na.rm = TRUE), 1), "Avg Age", icon = icon("user"), color = "blue")
  })
  
  output$cameraRate <- renderValueBox({
    rate <- mean(filtered_data()$HasCamera, na.rm = TRUE) * 100
    valueBox(paste0(round(rate, 1), "%"), "With Cameras", icon = icon("video"), color = "purple")
  })
  
  output$yearlyTrend <- renderPlotly({
    data <- filtered_data() %>% group_by(Year) %>% summarise(Count = n())
    plot_ly(data, x = ~Year, y = ~Count, type = 'bar', marker = list(color = '#dd4b39'))
  })
  
  output$monthlyDist <- renderPlotly({
    data <- filtered_data() %>% group_by(Month) %>% summarise(Count = n())
    plot_ly(data, x = ~Month, y = ~Count, type = 'bar', marker = list(color = '#dd4b39'))
  })
  
  output$topLocations <- renderPlotly({
    data <- filtered_data() %>%
      filter(!is.na(Address) & Address != "") %>%
      mutate(Street = gsub("^\\d+\\s+", "", Address)) %>%
      group_by(Street) %>% summarise(Count = n()) %>%
      arrange(desc(Count)) %>% head(10)
    plot_ly(data, x = ~Count, y = ~reorder(Street, Count), type = 'bar', orientation = 'h', marker = list(color = '#dd4b39'))
  })
  
  output$timeSeriesPlot <- renderPlotly({
    data <- filtered_data() %>%
      mutate(YearMonth = floor_date(Date, "month")) %>%
      group_by(YearMonth) %>% summarise(Count = n())
    plot_ly(data, x = ~YearMonth, y = ~Count, type = 'scatter', mode = 'lines+markers', line = list(color = '#dd4b39'))
  })
  
  output$dayOfWeekPlot <- renderPlotly({
    data <- filtered_data() %>%
      mutate(DayOfWeek = wday(Date, label = TRUE)) %>%
      group_by(DayOfWeek) %>% summarise(Count = n())
    plot_ly(data, x = ~DayOfWeek, y = ~Count, type = 'bar', marker = list(color = '#dd4b39'))
  })
  
  output$heatmapPlot <- renderPlotly({
    data <- filtered_data() %>% group_by(Year, Month) %>% summarise(Count = n(), .groups = 'drop')
    plot_ly(data, x = ~Year, y = ~Month, z = ~Count, type = 'heatmap', colors = colorRamp(c("white", "#dd4b39")))
  })
  
  output$cameraClosureRate <- renderPlotly({
    data <- filtered_data() %>%
      group_by(HasCamera) %>%
      summarise(Total = n(), Closed = sum(IsClosed, na.rm = TRUE), Rate = Closed / Total * 100) %>%
      mutate(Status = ifelse(HasCamera, "With Camera", "Without Camera"))
    plot_ly(data, x = ~Status, y = ~Rate, type = 'bar', marker = list(color = '#dd4b39'))
  })
  
  output$cameraByYear <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Year, HasCamera) %>% summarise(Count = n(), .groups = 'drop') %>%
      mutate(Status = ifelse(HasCamera, "With", "Without"))
    plot_ly(data, x = ~Year, y = ~Count, color = ~Status, type = 'bar', colors = c('#dd4b39', '#ff7f50'))
  })
  
  output$closureComparison <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Year, HasCamera) %>%
      summarise(Total = n(), Closed = sum(IsClosed, na.rm = TRUE), Rate = Closed / Total * 100, .groups = 'drop') %>%
      mutate(Status = ifelse(HasCamera, "With", "Without"))
    plot_ly(data, x = ~Year, y = ~Rate, color = ~Status, type = 'scatter', mode = 'lines+markers')
  })
  
  output$ageDistribution <- renderPlotly({
    data <- filtered_data() %>% filter(!is.na(Age) & Age > 0)
    plot_ly(data, x = ~Age, type = 'histogram', marker = list(color = '#dd4b39'), nbinsx = 30)
  })
  
  output$ageByYear <- renderPlotly({
    data <- filtered_data() %>% filter(!is.na(Age) & Age > 0) %>%
      group_by(Year) %>% summarise(AvgAge = mean(Age, na.rm = TRUE))
    plot_ly(data, x = ~Year, y = ~AvgAge, type = 'scatter', mode = 'lines+markers', line = list(color = '#dd4b39'))
  })
  
  output$ageByMonth <- renderPlotly({
    data <- filtered_data() %>% filter(!is.na(Age) & Age > 0) %>%
      group_by(Month) %>% summarise(AvgAge = mean(Age, na.rm = TRUE), .groups = 'drop')
    plot_ly(data, x = ~Month, y = ~AvgAge, type = 'bar', marker = list(color = '#dd4b39'))
  })
  
  output$caseStatusPie <- renderPlotly({
    data <- filtered_data() %>%
      summarise(Closed = sum(IsClosed, na.rm = TRUE), Open = sum(!IsClosed, na.rm = TRUE)) %>%
      pivot_longer(cols = everything(), names_to = "Status", values_to = "Count")
    plot_ly(data, labels = ~Status, values = ~Count, type = 'pie', marker = list(colors = c('#4CAF50', '#dd4b39')))
  })
  
  output$closureByYear <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Year) %>%
      summarise(Total = n(), Closed = sum(IsClosed, na.rm = TRUE), Rate = Closed / Total * 100)
    plot_ly(data, x = ~Year, y = ~Rate, type = 'bar', marker = list(color = '#dd4b39'))
  })
  
  output$closureTimeline <- renderPlotly({
    data <- filtered_data() %>%
      mutate(YearMonth = floor_date(Date, "month")) %>%
      group_by(YearMonth, IsClosed) %>% summarise(Count = n(), .groups = 'drop') %>%
      mutate(Status = ifelse(IsClosed, "Closed", "Open"))
    plot_ly(data, x = ~YearMonth, y = ~Count, color = ~Status, type = 'bar', colors = c('#4CAF50', '#dd4b39'))
  })
  
  output$dataTable <- renderDT({
    filtered_data() %>%
      select(No, Date, Name, Age, Address, SurveillanceCamera, CaseClosed) %>%
      datatable(options = list(pageLength = 25, scrollX = TRUE), filter = 'top', rownames = FALSE)
  })
}

shinyApp(ui, server)