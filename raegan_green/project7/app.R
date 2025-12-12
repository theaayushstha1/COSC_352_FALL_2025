# Baltimore Homicide Dashboard - R Shiny Application
# Project 7 - COSC 352 Fall 2025

library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(lubridate)
library(httr)
library(xml2)
library(stringr)
library(plotly)
library(DT)

# Data URLs
urls <- c(
  "2021" = "http://chamspage.blogspot.com/2021/",
  "2022" = "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
  "2023" = "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
  "2024" = "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
  "2025" = "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
)

# Function to fetch and parse homicide data
fetch_homicide_data <- function() {
  all_records <- list()
  
  for (year_name in names(urls)) {
    cat("Fetching data for", year_name, "...\n")
    
    tryCatch({
      response <- GET(urls[year_name], 
                     user_agent("Mozilla/5.0"),
                     timeout(30))
      
      if (status_code(response) == 200) {
        html_content <- content(response, "text", encoding = "UTF-8")
        
        # Extract table cells
        td_pattern <- "<td>(.*?)</td>"
        matches <- str_match_all(html_content, td_pattern)[[1]]
        
        if (nrow(matches) > 0) {
          cells <- matches[, 2]
          
          # Clean HTML from cells
          cells <- gsub("<[^>]*>", "", cells)
          cells <- gsub("&nbsp;", " ", cells)
          cells <- gsub("&amp;", "&", cells)
          cells <- trimws(cells)
          
          # Process cells in groups of 9
          i <- 1
          while (i + 8 <= length(cells)) {
            num_str <- cells[i]
            date_str <- cells[i + 1]
            name_str <- cells[i + 2]
            age_str <- cells[i + 3]
            address_str <- cells[i + 4]
            closed_str <- tolower(cells[i + 8])
            
            # Validate record format
            if (grepl("^\\d{3}$", num_str) && grepl("^\\d{2}/\\d{2}/\\d{2}$", date_str)) {
              age <- suppressWarnings(as.integer(age_str))
              
              # Extract year from date
              date_parts <- strsplit(date_str, "/")[[1]]
              if (length(date_parts) == 3) {
                year_part <- date_parts[3]
                if (nchar(year_part) == 2) {
                  year <- 2000 + as.integer(year_part)
                } else {
                  year <- as.integer(year_part)
                }
                
                if (!is.na(age) && age > 0 && year >= 2020 && year <= 2025 && nchar(address_str) > 3) {
                  all_records[[length(all_records) + 1]] <- data.frame(
                    date = date_str,
                    name = name_str,
                    age = age,
                    address = address_str,
                    year = year,
                    closed = grepl("closed", closed_str),
                    stringsAsFactors = FALSE
                  )
                }
              }
              
              i <- i + 9
            } else {
              i <- i + 1
            }
          }
        }
      }
    }, error = function(e) {
      cat("Error fetching", year_name, ":", conditionMessage(e), "\n")
    })
  }
  
  if (length(all_records) > 0) {
    df <- do.call(rbind, all_records)
    cat("Total records loaded:", nrow(df), "\n")
    return(df)
  } else {
    return(data.frame())
  }
}

# Load data on startup
cat("Loading Baltimore homicide data...\n")
homicide_data <- fetch_homicide_data()

if (nrow(homicide_data) == 0) {
  stop("No data loaded. Please check internet connection and data sources.")
}

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Baltimore Homicide Analysis (2021-2025)"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Trends", tabName = "trends", icon = icon("chart-line")),
      menuItem("Demographics", tabName = "demographics", icon = icon("users")),
      menuItem("Case Status", tabName = "cases", icon = icon("gavel")),
      menuItem("Data Table", tabName = "data", icon = icon("table"))
    ),
    hr(),
    p(paste("Total Records:", nrow(homicide_data)), style = "color: white; padding: 10px;"),
    p(paste("Years:", min(homicide_data$year), "-", max(homicide_data$year)), 
      style = "color: white; padding: 10px;")
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #f4f4f4; }
        .box { border-radius: 5px; }
      "))
    ),
    
    tabItems(
      # Overview Tab
      tabItem(tabName = "overview",
        fluidRow(
          valueBoxOutput("totalHomicides", width = 3),
          valueBoxOutput("closureRate", width = 3),
          valueBoxOutput("avgAge", width = 3),
          valueBoxOutput("youthVictims", width = 3)
        ),
        fluidRow(
          box(
            title = "Homicides by Year",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("yearBarChart", height = 300)
          ),
          box(
            title = "Monthly Distribution",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("monthlyChart", height = 300)
          )
        ),
        fluidRow(
          box(
            title = "Key Insights",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            htmlOutput("keyInsights")
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
            plotlyOutput("trendChart", height = 400)
          )
        ),
        fluidRow(
          box(
            title = "Year-over-Year Comparison",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("yoyChart", height = 300)
          ),
          box(
            title = "Closure Rate Trends",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("closureTrendChart", height = 300)
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
            plotlyOutput("ageHistogram", height = 350)
          ),
          box(
            title = "Age Groups",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("ageGroupChart", height = 350)
          )
        ),
        fluidRow(
          box(
            title = "Top 10 Most Common Ages",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("topAgesChart", height = 300)
          ),
          box(
            title = "Youth Violence Analysis",
            status = "danger",
            solidHeader = TRUE,
            width = 6,
            htmlOutput("youthAnalysis")
          )
        )
      ),
      
      # Case Status Tab
      tabItem(tabName = "cases",
        fluidRow(
          box(
            title = "Case Closure Status",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("closureStatusChart", height = 300)
          ),
          box(
            title = "Closure Rate by Year",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("closureByYearChart", height = 300)
          )
        ),
        fluidRow(
          box(
            title = "Case Statistics Table",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DTOutput("caseStatsTable")
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
            DTOutput("dataTable")
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Value Boxes
  output$totalHomicides <- renderValueBox({
    valueBox(
      nrow(homicide_data),
      "Total Homicides",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  output$closureRate <- renderValueBox({
    rate <- round(sum(homicide_data$closed) / nrow(homicide_data) * 100, 1)
    valueBox(
      paste0(rate, "%"),
      "Case Closure Rate",
      icon = icon("check-circle"),
      color = if(rate > 30) "green" else "red"
    )
  })
  
  output$avgAge <- renderValueBox({
    avg <- round(mean(homicide_data$age, na.rm = TRUE), 1)
    valueBox(
      avg,
      "Average Victim Age",
      icon = icon("user"),
      color = "blue"
    )
  })
  
  output$youthVictims <- renderValueBox({
    youth <- sum(homicide_data$age <= 18)
    valueBox(
      youth,
      "Youth Victims (≤18)",
      icon = icon("child"),
      color = "orange"
    )
  })
  
  # Charts
  output$yearBarChart <- renderPlotly({
    yearly_counts <- homicide_data %>%
      group_by(year) %>%
      summarise(count = n())
    
    plot_ly(yearly_counts, x = ~year, y = ~count, type = "bar",
            marker = list(color = "steelblue")) %>%
      layout(xaxis = list(title = "Year"),
             yaxis = list(title = "Number of Homicides"),
             hovermode = "x")
  })
  
  output$monthlyChart <- renderPlotly({
    homicide_data$month <- as.integer(substr(homicide_data$date, 1, 2))
    
    monthly_counts <- homicide_data %>%
      group_by(month) %>%
      summarise(count = n()) %>%
      arrange(month)
    
    plot_ly(monthly_counts, x = ~month, y = ~count, type = "scatter", mode = "lines+markers",
            line = list(color = "darkgreen", width = 3),
            marker = list(size = 8)) %>%
      layout(xaxis = list(title = "Month", tickvals = 1:12),
             yaxis = list(title = "Number of Homicides"))
  })
  
  output$trendChart <- renderPlotly({
    trend_data <- homicide_data %>%
      mutate(month_year = paste0(year, "-", sprintf("%02d", as.integer(substr(date, 1, 2))))) %>%
      group_by(month_year, year) %>%
      summarise(count = n(), .groups = "drop") %>%
      arrange(month_year)
    
    plot_ly(trend_data, x = ~month_year, y = ~count, color = ~as.factor(year),
            type = "scatter", mode = "lines+markers") %>%
      layout(xaxis = list(title = "Month-Year"),
             yaxis = list(title = "Homicides"),
             showlegend = TRUE)
  })
  
  output$ageHistogram <- renderPlotly({
    plot_ly(homicide_data, x = ~age, type = "histogram",
            marker = list(color = "purple")) %>%
      layout(xaxis = list(title = "Age"),
             yaxis = list(title = "Count"),
             bargap = 0.1)
  })
  
  output$ageGroupChart <- renderPlotly({
    age_groups <- homicide_data %>%
      mutate(age_group = case_when(
        age <= 12 ~ "Children (0-12)",
        age <= 18 ~ "Teens (13-18)",
        age <= 30 ~ "Young Adults (19-30)",
        age <= 50 ~ "Adults (31-50)",
        TRUE ~ "Seniors (51+)"
      )) %>%
      group_by(age_group) %>%
      summarise(count = n())
    
    plot_ly(age_groups, labels = ~age_group, values = ~count, type = "pie") %>%
      layout(title = "")
  })
  
  output$topAgesChart <- renderPlotly({
    top_ages <- homicide_data %>%
      group_by(age) %>%
      summarise(count = n()) %>%
      arrange(desc(count)) %>%
      head(10)
    
    plot_ly(top_ages, x = ~reorder(age, count), y = ~count, type = "bar",
            marker = list(color = "coral")) %>%
      layout(xaxis = list(title = "Age"),
             yaxis = list(title = "Count"))
  })
  
  output$closureStatusChart <- renderPlotly({
    closure_data <- data.frame(
      Status = c("Closed", "Open"),
      Count = c(sum(homicide_data$closed), sum(!homicide_data$closed))
    )
    
    plot_ly(closure_data, labels = ~Status, values = ~Count, type = "pie",
            marker = list(colors = c("green", "red"))) %>%
      layout(title = "")
  })
  
  output$closureByYearChart <- renderPlotly({
    closure_by_year <- homicide_data %>%
      group_by(year) %>%
      summarise(
        total = n(),
        closed = sum(closed),
        rate = round(closed / total * 100, 1)
      )
    
    plot_ly(closure_by_year, x = ~year, y = ~rate, type = "bar",
            marker = list(color = "teal"),
            text = ~paste0(rate, "%"), textposition = "outside") %>%
      layout(xaxis = list(title = "Year"),
             yaxis = list(title = "Closure Rate (%)", range = c(0, 100)))
  })
  
  output$yoyChart <- renderPlotly({
    yearly_counts <- homicide_data %>%
      group_by(year) %>%
      summarise(count = n())
    
    plot_ly(yearly_counts, x = ~year, y = ~count, type = "scatter", mode = "lines+markers",
            line = list(color = "darkblue", width = 3),
            marker = list(size = 10)) %>%
      layout(xaxis = list(title = "Year"),
             yaxis = list(title = "Total Homicides"))
  })
  
  output$closureTrendChart <- renderPlotly({
    closure_by_year <- homicide_data %>%
      group_by(year) %>%
      summarise(rate = round(sum(closed) / n() * 100, 1))
    
    plot_ly(closure_by_year, x = ~year, y = ~rate, type = "scatter", mode = "lines+markers",
            line = list(color = "green", width = 3),
            marker = list(size = 10)) %>%
      layout(xaxis = list(title = "Year"),
             yaxis = list(title = "Closure Rate (%)", range = c(0, 100)))
  })
  
  # Tables
  output$caseStatsTable <- renderDT({
    stats <- homicide_data %>%
      group_by(year) %>%
      summarise(
        `Total Cases` = n(),
        `Closed` = sum(closed),
        `Open` = sum(!closed),
        `Closure Rate (%)` = round(sum(closed) / n() * 100, 1)
      )
    
    datatable(stats, options = list(dom = 't', ordering = FALSE))
  })
  
  output$dataTable <- renderDT({
    display_data <- homicide_data %>%
      select(date, name, age, address, year, closed) %>%
      mutate(closed = ifelse(closed, "Yes", "No"))
    
    datatable(display_data, 
              options = list(pageLength = 25, scrollX = TRUE),
              filter = "top")
  })
  
  # Text outputs
  output$keyInsights <- renderUI({
    total <- nrow(homicide_data)
    closed_rate <- round(sum(homicide_data$closed) / total * 100, 1)
    youth <- sum(homicide_data$age <= 18)
    youth_pct <- round(youth / total * 100, 1)
    
    most_deadly_year <- homicide_data %>%
      group_by(year) %>%
      summarise(count = n()) %>%
      arrange(desc(count)) %>%
      head(1)
    
    HTML(paste(
      "<ul>",
      "<li><strong>Total homicides (2021-2025):</strong>", total, "</li>",
      "<li><strong>Overall closure rate:</strong>", closed_rate, "%</li>",
      "<li><strong>Youth victims (≤18):</strong>", youth, "(", youth_pct, "% of total)</li>",
      "<li><strong>Deadliest year:</strong>", most_deadly_year$year, "with", most_deadly_year$count, "homicides</li>",
      "</ul>"
    ))
  })
  
  output$youthAnalysis <- renderUI({
    children <- sum(homicide_data$age <= 12)
    teens <- sum(homicide_data$age >= 13 & homicide_data$age <= 18)
    youth_total <- children + teens
    youth_pct <- round(youth_total / nrow(homicide_data) * 100, 1)
    
    HTML(paste(
      "<h4>Youth Violence Statistics</h4>",
      "<ul>",
      "<li><strong>Children (0-12):</strong>", children, "victims</li>",
      "<li><strong>Teens (13-18):</strong>", teens, "victims</li>",
      "<li><strong>Total Youth:</strong>", youth_total, "victims</li>",
      "<li><strong>Percentage:</strong>", youth_pct, "% of all homicides</li>",
      "</ul>",
      if (children > 0) paste("<p style='color:red;'><strong>ALERT:</strong>", children, "children under 13 killed</p>") else "",
      if (teens > 0) paste("<p style='color:orange;'><strong>URGENT:</strong>", teens, "teenagers killed</p>") else ""
    ))
  })
}

# Run the application
shinyApp(ui = ui, server = server)