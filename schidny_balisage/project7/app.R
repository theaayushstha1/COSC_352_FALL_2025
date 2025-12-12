# Baltimore City Homicides Dashboard (2021-2025)
# Project 7 - COSC 352

library(shiny)
library(shinydashboard)
library(rvest)
library(dplyr)
library(ggplot2)
library(lubridate)
library(DT)
library(plotly)
library(tidyr)

# Function to scrape homicide data from blog pages
scrape_homicides <- function(year) {
  base_url <- "http://chamspage.blogspot.com"
  
  url <- if (year == 2021) {
    paste0(base_url, "/2021/")
  } else {
    paste0(base_url, "/", year, "/01/", year, "-baltimore-city-homicide", 
           ifelse(year > 2021, "s", ""), "-list.html")
  }
  
  tryCatch({
    page <- read_html(url)
    
    # Extract the text content from the blog post
    post_content <- page %>%
      html_nodes(".post-body") %>%
      html_text()
    
    # Parse the homicide entries (format: number. Name, Age, Date, Location)
    lines <- strsplit(post_content, "\n")[[1]]
    lines <- trimws(lines[nzchar(trimws(lines))])
    
    # Filter lines that start with numbers (homicide entries)
    entries <- grep("^\\d+\\.", lines, value = TRUE)
    
    homicides <- lapply(entries, function(entry) {
      # Remove the leading number
      entry <- sub("^\\d+\\.\\s*", "", entry)
      
      # Parse the entry (format varies, so we'll be flexible)
      parts <- strsplit(entry, ",")[[1]]
      
      if (length(parts) >= 3) {
        name <- trimws(parts[1])
        age <- trimws(parts[2])
        date_loc <- trimws(paste(parts[3:length(parts)], collapse = ", "))
        
        # Try to extract date (various formats)
        date_match <- regexpr("\\d{1,2}/\\d{1,2}", date_loc)
        date_str <- if (date_match > 0) {
          substr(date_loc, date_match, date_match + attr(date_match, "match.length") - 1)
        } else {
          NA
        }
        
        # Convert to full date
        if (!is.na(date_str)) {
          date_str <- paste0(date_str, "/", year)
          date <- mdy(date_str)
        } else {
          date <- NA
        }
        
        # Extract location (everything after date)
        location <- if (!is.na(date_str)) {
          sub(paste0(".*", date_str, "\\s*"), "", date_loc)
        } else {
          date_loc
        }
        
        data.frame(
          year = year,
          name = name,
          age = age,
          date = date,
          location = trimws(location),
          stringsAsFactors = FALSE
        )
      } else {
        NULL
      }
    })
    
    do.call(rbind, homicides[!sapply(homicides, is.null)])
    
  }, error = function(e) {
    warning(paste("Error scraping year", year, ":", e$message))
    data.frame(
      year = integer(),
      name = character(),
      age = character(),
      date = as.Date(character()),
      location = character(),
      stringsAsFactors = FALSE
    )
  })
}

# Load all data
load_all_data <- function() {
  years <- 2021:2025
  all_data <- lapply(years, scrape_homicides)
  combined <- do.call(rbind, all_data)
  
  # Clean age data (convert to numeric)
  combined$age_numeric <- as.numeric(gsub("[^0-9]", "", combined$age))
  
  # Add month and day of year for analysis
  combined$month <- month(combined$date, label = TRUE)
  combined$day_of_year <- yday(combined$date)
  
  return(combined)
}

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Baltimore City Homicides (2021-2025)"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Trends", tabName = "trends", icon = icon("chart-line")),
      menuItem("Demographics", tabName = "demographics", icon = icon("users")),
      menuItem("Locations", tabName = "locations", icon = icon("map-marker")),
      menuItem("Data Table", tabName = "data", icon = icon("table")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                valueBoxOutput("total_homicides"),
                valueBoxOutput("current_year_homicides"),
                valueBoxOutput("avg_age")
              ),
              fluidRow(
                box(
                  title = "Homicides by Year",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("homicides_by_year")
                ),
                box(
                  title = "Monthly Distribution (All Years)",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("monthly_distribution")
                )
              )
      ),
      
      # Trends Tab
      tabItem(tabName = "trends",
              fluidRow(
                box(
                  title = "Cumulative Homicides by Year",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("cumulative_trends", height = 400)
                )
              ),
              fluidRow(
                box(
                  title = "Monthly Trends Across Years",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("monthly_trends", height = 400)
                )
              )
      ),
      
      # Demographics Tab
      tabItem(tabName = "demographics",
              fluidRow(
                box(
                  title = "Age Distribution",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("age_distribution")
                ),
                box(
                  title = "Age Group by Year",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("age_by_year")
                )
              ),
              fluidRow(
                box(
                  title = "Age Statistics by Year",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  DT::dataTableOutput("age_stats")
                )
              )
      ),
      
      # Locations Tab
      tabItem(tabName = "locations",
              fluidRow(
                box(
                  title = "Top 20 Locations",
                  status = "danger",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("top_locations", height = 600)
                )
              )
      ),
      
      # Data Table Tab
      tabItem(tabName = "data",
              fluidRow(
                box(
                  title = "Complete Homicide Data",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  DT::dataTableOutput("data_table")
                )
              )
      ),
      
      # About Tab
      tabItem(tabName = "about",
              fluidRow(
                box(
                  title = "About This Dashboard",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Baltimore City Homicides Dashboard"),
                  p("This dashboard visualizes homicide data from Baltimore City for the years 2021-2025."),
                  h4("Data Source"),
                  p("Data is scraped from Cham's Baltimore Crime Blog:"),
                  tags$ul(
                    tags$li(tags$a(href="http://chamspage.blogspot.com/2021/", "2021 Data")),
                    tags$li(tags$a(href="http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html", "2022 Data")),
                    tags$li(tags$a(href="http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html", "2023 Data")),
                    tags$li(tags$a(href="http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html", "2024 Data")),
                    tags$li(tags$a(href="http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html", "2025 Data"))
                  ),
                  h4("Features"),
                  tags$ul(
                    tags$li("Overview statistics and yearly comparisons"),
                    tags$li("Temporal trends and cumulative analysis"),
                    tags$li("Demographic breakdowns by age"),
                    tags$li("Location-based analysis"),
                    tags$li("Interactive data table with search and filtering")
                  ),
                  h4("Project Information"),
                  p("COSC 352 - Fall 2025"),
                  p("Project 7: R Shiny Dashboard"),
                  p("Author: [Your Name]")
                )
              )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Load data
  homicide_data <- reactive({
    load_all_data()
  })
  
  # Value boxes
  output$total_homicides <- renderValueBox({
    data <- homicide_data()
    valueBox(
      nrow(data),
      "Total Homicides (2021-2025)",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  output$current_year_homicides <- renderValueBox({
    data <- homicide_data()
    current <- sum(data$year == 2025, na.rm = TRUE)
    valueBox(
      current,
      "2025 Homicides (YTD)",
      icon = icon("calendar"),
      color = "orange"
    )
  })
  
  output$avg_age <- renderValueBox({
    data <- homicide_data()
    avg <- round(mean(data$age_numeric, na.rm = TRUE), 1)
    valueBox(
      avg,
      "Average Age",
      icon = icon("user"),
      color = "blue"
    )
  })
  
  # Homicides by year
  output$homicides_by_year <- renderPlotly({
    data <- homicide_data()
    yearly <- data %>%
      group_by(year) %>%
      summarise(count = n())
    
    plot_ly(yearly, x = ~year, y = ~count, type = 'bar',
            marker = list(color = 'rgb(158,202,225)',
                          line = list(color = 'rgb(8,48,107)', width = 1.5))) %>%
      layout(title = "",
             xaxis = list(title = "Year"),
             yaxis = list(title = "Number of Homicides"))
  })
  
  # Monthly distribution
  output$monthly_distribution <- renderPlotly({
    data <- homicide_data()
    monthly <- data %>%
      filter(!is.na(month)) %>%
      group_by(month) %>%
      summarise(count = n())
    
    plot_ly(monthly, x = ~month, y = ~count, type = 'bar',
            marker = list(color = 'rgb(204,102,119)')) %>%
      layout(title = "",
             xaxis = list(title = "Month"),
             yaxis = list(title = "Number of Homicides"))
  })
  
  # Cumulative trends
  output$cumulative_trends <- renderPlotly({
    data <- homicide_data() %>%
      filter(!is.na(day_of_year))
    
    cumulative <- data %>%
      arrange(year, day_of_year) %>%
      group_by(year) %>%
      mutate(cumulative = row_number())
    
    plot_ly(cumulative, x = ~day_of_year, y = ~cumulative, color = ~as.factor(year),
            type = 'scatter', mode = 'lines') %>%
      layout(title = "",
             xaxis = list(title = "Day of Year"),
             yaxis = list(title = "Cumulative Homicides"),
             legend = list(title = list(text = "Year")))
  })
  
  # Monthly trends
  output$monthly_trends <- renderPlotly({
    data <- homicide_data() %>%
      filter(!is.na(month))
    
    monthly <- data %>%
      group_by(year, month) %>%
      summarise(count = n(), .groups = 'drop')
    
    plot_ly(monthly, x = ~month, y = ~count, color = ~as.factor(year),
            type = 'scatter', mode = 'lines+markers') %>%
      layout(title = "",
             xaxis = list(title = "Month"),
             yaxis = list(title = "Number of Homicides"),
             legend = list(title = list(text = "Year")))
  })
  
  # Age distribution
  output$age_distribution <- renderPlotly({
    data <- homicide_data() %>%
      filter(!is.na(age_numeric))
    
    plot_ly(data, x = ~age_numeric, type = 'histogram',
            marker = list(color = 'rgb(102,194,165)')) %>%
      layout(title = "",
             xaxis = list(title = "Age"),
             yaxis = list(title = "Count"))
  })
  
  # Age by year
  output$age_by_year <- renderPlotly({
    data <- homicide_data() %>%
      filter(!is.na(age_numeric)) %>%
      mutate(age_group = cut(age_numeric, 
                             breaks = c(0, 18, 25, 35, 45, 55, 100),
                             labels = c("0-17", "18-24", "25-34", "35-44", "45-54", "55+")))
    
    age_year <- data %>%
      group_by(year, age_group) %>%
      summarise(count = n(), .groups = 'drop')
    
    plot_ly(age_year, x = ~as.factor(year), y = ~count, color = ~age_group,
            type = 'bar') %>%
      layout(title = "",
             xaxis = list(title = "Year"),
             yaxis = list(title = "Number of Homicides"),
             barmode = 'stack',
             legend = list(title = list(text = "Age Group")))
  })
  
  # Age statistics
  output$age_stats <- DT::renderDataTable({
    data <- homicide_data() %>%
      filter(!is.na(age_numeric))
    
    stats <- data %>%
      group_by(year) %>%
      summarise(
        Count = n(),
        `Min Age` = min(age_numeric),
        `Mean Age` = round(mean(age_numeric), 1),
        `Median Age` = median(age_numeric),
        `Max Age` = max(age_numeric)
      )
    
    DT::datatable(stats, options = list(pageLength = 10, dom = 't'))
  })
  
  # Top locations
  output$top_locations <- renderPlotly({
    data <- homicide_data()
    
    top_loc <- data %>%
      group_by(location) %>%
      summarise(count = n()) %>%
      arrange(desc(count)) %>%
      head(20)
    
    plot_ly(top_loc, y = ~reorder(location, count), x = ~count,
            type = 'bar', orientation = 'h',
            marker = list(color = 'rgb(252,141,98)')) %>%
      layout(title = "",
             xaxis = list(title = "Number of Homicides"),
             yaxis = list(title = ""),
             margin = list(l = 200))
  })
  
  # Data table
  output$data_table <- DT::renderDataTable({
    data <- homicide_data() %>%
      select(year, name, age, date, location)
    
    DT::datatable(data, 
                  options = list(pageLength = 25, 
                                scrollX = TRUE,
                                searchHighlight = TRUE),
                  filter = 'top')
  })
}

# Run the app
shinyApp(ui, server)
