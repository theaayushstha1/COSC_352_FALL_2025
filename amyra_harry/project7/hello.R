library(shiny)
library(shinydashboard)
library(rvest)
library(dplyr)
library(plotly)
library(lubridate)
library(DT)
library(tidyr)

# ---------------------------------------------------------
# DATA PROCESSING FUNCTIONS
# ---------------------------------------------------------

detect_age_column <- function(df) {
  scores <- sapply(df, function(col) {
    nums <- suppressWarnings(as.numeric(col))
    sum(nums >= 1 & nums <= 120, na.rm = TRUE)
  })
  if (max(scores) > 0) return(names(scores)[which.max(scores)])
  return(NULL)
}

detect_gender_column <- function(df) {
  idx <- grep("gender|sex", names(df), ignore.case = TRUE)
  if (length(idx) == 1) return(names(df)[idx])
  return(NULL)
}

detect_weapon_column <- function(df) {
  idx <- grep("cause|weapon|method|notes", names(df), ignore.case = TRUE)
  if (length(idx) >= 1) return(names(df)[idx[1]])
  return(NULL)
}

detect_date_column <- function(df) {
  idx <- grep("date|died", names(df), ignore.case = TRUE)
  if (length(idx) >= 1) return(names(df)[idx[1]])
  return(NULL)
}

detect_location_column <- function(df) {
  idx <- grep("address.*block.*found|block.*found|address", names(df), ignore.case = TRUE)
  if (length(idx) >= 1) return(names(df)[idx[1]])
  return(NULL)
}

detect_name_column <- function(df) {
  idx <- grep("^name$", names(df), ignore.case = TRUE)
  if (length(idx) >= 1) return(names(df)[idx[1]])
  return(NULL)
}

detect_case_status_column <- function(df) {
  idx <- grep("case.*closed", names(df), ignore.case = TRUE)
  if (length(idx) >= 1) return(names(df)[idx[1]])
  return(NULL)
}

safe_scrape <- function(url, year) {
  tryCatch({
    message("Scraping ", url)
    page <- read_html(url)
    tables <- page %>% html_elements("table")
    if (length(tables) == 0) {
      message("No tables found")
      return(NULL)
    }
    
    df <- tables[[1]] %>% html_table(fill = TRUE)
    if (nrow(df) == 0 || ncol(df) < 3) {
      message("Table is empty or has too few columns")
      return(NULL)
    }
    
    message("Found table with ", nrow(df), " rows and ", ncol(df), " columns")
    
    df$Year <- year
    
    # Detect and rename columns
    name_col <- detect_name_column(df)
    if (!is.null(name_col) && name_col %in% names(df)) {
      names(df)[names(df) == name_col] <- "Name"
    }
    
    age_col <- detect_age_column(df)
    if (!is.null(age_col) && age_col %in% names(df)) {
      names(df)[names(df) == age_col] <- "Age"
    }
    
    gender_col <- detect_gender_column(df)
    if (!is.null(gender_col) && gender_col %in% names(df)) {
      names(df)[gender_col] <- "Gender"
    }
    
    weapon_col <- detect_weapon_column(df)
    if (!is.null(weapon_col) && weapon_col %in% names(df)) {
      names(df)[weapon_col] <- "Weapon"
    }
    
    date_col <- detect_date_column(df)
    if (!is.null(date_col) && date_col %in% names(df)) {
      names(df)[date_col] <- "Date"
    }
    
    location_col <- detect_location_column(df)
    if (!is.null(location_col) && location_col %in% names(df)) {
      names(df)[location_col] <- "AddressBlockFound"
    }
    
    case_col <- detect_case_status_column(df)
    if (!is.null(case_col) && case_col %in% names(df)) {
      names(df)[case_col] <- "CaseClosed"
    }
    
    return(df)
  }, error = function(e) {
    message("Error scraping ", url, ": ", e$message)
    return(NULL)
  })
}

# ---------------------------------------------------------
# LOAD DATA
# ---------------------------------------------------------

message("Starting data load...")

urls <- list(
  list(url = "https://chamspage.blogspot.com/2021/", year = 2021),
  list(url = "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html", year = 2022),
  list(url = "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html", year = 2023),
  list(url = "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html", year = 2024),
  list(url = "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html", year = 2025)
)

tables_list <- lapply(urls, function(x) safe_scrape(x$url, x$year))
tables_list <- Filter(Negate(is.null), tables_list)

if (length(tables_list) == 0) {
  stop("No data could be scraped from the URLs")
}

message("Successfully loaded ", length(tables_list), " tables")

combined <- bind_rows(tables_list)
message("Combined data has ", nrow(combined), " rows")
message("Columns found: ", paste(names(combined), collapse = ", "))

# Clean Age
if (!"Age" %in% names(combined)) {
  age_col <- detect_age_column(combined)
  if (!is.null(age_col)) names(combined)[names(combined) == age_col] <- "Age"
}
combined$Age <- suppressWarnings(as.numeric(combined$Age))

# Parse dates if available
if ("Date" %in% names(combined)) {
  combined$DateOriginal <- combined$Date
  combined$Date <- suppressWarnings(mdy(combined$Date))
  combined$Month <- month(combined$Date, label = TRUE, abbr = TRUE)
  combined$MonthNum <- month(combined$Date)
}

# Categorize weapons
if ("Weapon" %in% names(combined)) {
  combined$WeaponCategory <- case_when(
    grepl("shoot|gun|firearm", combined$Weapon, ignore.case = TRUE) ~ "Shooting",
    grepl("stab|knife|cut", combined$Weapon, ignore.case = TRUE) ~ "Stabbing",
    grepl("blunt|beat|trauma", combined$Weapon, ignore.case = TRUE) ~ "Blunt Force",
    grepl("strangle|chok|asphyxia", combined$Weapon, ignore.case = TRUE) ~ "Strangulation",
    TRUE ~ "Other"
  )
}

# Age groups
combined$AgeGroup <- cut(combined$Age, 
                         breaks = c(0, 17, 24, 34, 49, 64, 120),
                         labels = c("0-17", "18-24", "25-34", "35-49", "50-64", "65+"),
                         include.lowest = TRUE)

message("Data processing complete")

# ---------------------------------------------------------
# UI
# ---------------------------------------------------------

ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(title = "Baltimore Homicide Dashboard", titleWidth = 300),
  
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      menuItem("Demographics", tabName = "demographics", icon = icon("users")),
      menuItem("Trends", tabName = "trends", icon = icon("chart-line")),
      menuItem("Data Table", tabName = "datatable", icon = icon("table"))
    ),
    
    hr(),
    h4("Filters", style = "padding-left: 15px; color: #ecf0f5;"),
    
    selectInput("yearFilter", "Year:", 
                choices = c("All Years", sort(unique(combined$Year), decreasing = TRUE)),
                selected = "All Years"),
    
    sliderInput("ageFilter", "Age Range:",
                min = 0, max = 100, value = c(0, 100), step = 1),
    
    selectizeInput("addressFilter", "Address Block Found:",
                   choices = c("All Addresses" = ""),
                   multiple = FALSE,
                   options = list(
                     placeholder = 'Type to search addresses...',
                     maxOptions = 1000
                   )),
    
    conditionalPanel(
      condition = "input.yearFilter != 'All Years' || input.ageFilter[0] != 0 || input.ageFilter[1] != 100 || input.addressFilter != ''",
      hr(),
      actionButton("resetFilters", "Reset Filters", 
                   icon = icon("redo"), 
                   style = "margin-left: 15px; width: 85%; color: #fff; background-color: #3c8dbc;")
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #f4f6f9; }
        .box { border-top-color: #3c8dbc; box-shadow: 0 1px 3px rgba(0,0,0,0.12); }
        .small-box { border-radius: 5px; }
        h3 { color: #2c3e50; }
      "))
    ),
    
    tabItems(
      # DEMOGRAPHICS TAB
      tabItem(tabName = "demographics",
        fluidRow(
          valueBoxOutput("totalHomicides", width = 4),
          valueBoxOutput("avgAge", width = 4),
          valueBoxOutput("mostCommonAge", width = 4)
        ),
        
        fluidRow(
          box(title = "Age Distribution", status = "primary", solidHeader = TRUE, width = 8,
              plotlyOutput("ageDistPlot", height = "400px")),
          box(title = "Age Group Breakdown", status = "info", solidHeader = TRUE, width = 4,
              plotlyOutput("ageGroupPiePlot", height = "400px"))
        ),
        
        fluidRow(
          box(title = "Gender Distribution", status = "success", solidHeader = TRUE, width = 6,
              plotlyOutput("genderPlot", height = "350px")),
          box(title = "Method of Death", status = "warning", solidHeader = TRUE, width = 6,
              plotlyOutput("weaponPiePlot", height = "350px"))
        )
      ),
      
      # TRENDS TAB
      tabItem(tabName = "trends",
        fluidRow(
          valueBoxOutput("trendTotalDeaths", width = 4),
          valueBoxOutput("deadliestMonth", width = 4),
          valueBoxOutput("deadliestYear", width = 4)
        ),
        
        fluidRow(
          box(title = "Homicides by Year", status = "primary", solidHeader = TRUE, width = 6,
              plotlyOutput("yearlyBarPlot", height = "350px")),
          box(title = "Monthly Trend", status = "info", solidHeader = TRUE, width = 6,
              plotlyOutput("monthlyTrendPlot", height = "350px"))
        ),
        
        fluidRow(
          box(title = "Homicides Over Time", status = "warning", solidHeader = TRUE, width = 12,
              plotlyOutput("timeSeriesPlot", height = "350px"))
        ),
        
        fluidRow(
          box(title = "Method of Death by Year", status = "success", solidHeader = TRUE, width = 12,
              plotlyOutput("weaponTrendPlot", height = "350px"))
        )
      ),
      
      # DATA TABLE TAB
      tabItem(tabName = "datatable",
        fluidRow(
          box(title = "Homicide Records", status = "primary", solidHeader = TRUE, width = 12,
              p("Use the filters on the left sidebar to narrow down the data, or use the search boxes below each column to filter specific fields."),
              DTOutput("dataTable"))
        )
      )
    )
  )
)

# ---------------------------------------------------------
# SERVER
# ---------------------------------------------------------

server <- function(input, output, session) {
  
  # Extract unique addresses for the filter
  addresses <- c()
  if ("AddressBlockFound" %in% names(combined)) {
    addresses <- combined %>%
      filter(!is.na(AddressBlockFound) & AddressBlockFound != "" & AddressBlockFound != " ") %>%
      pull(AddressBlockFound) %>%
      unique() %>%
      sort()
    
    message("Found ", length(addresses), " unique address blocks")
  } else {
    message("Warning: AddressBlockFound column not found in data")
  }
  
  # Update address filter choices (client-side for better performance)
  observe({
    updateSelectizeInput(session, "addressFilter", 
                         choices = c("All Addresses" = "", addresses),
                         selected = "",
                         server = FALSE)
  })
  
  # Reactive filtered data
  filtered_data <- reactive({
    data <- combined
    
    # Year filter
    if (input$yearFilter != "All Years") {
      data <- data %>% filter(Year == as.numeric(input$yearFilter))
    }
    
    # Age filter
    data <- data %>% filter(is.na(Age) | (Age >= input$ageFilter[1] & Age <= input$ageFilter[2]))
    
    # Address filter
    if ("AddressBlockFound" %in% names(data) && !is.null(input$addressFilter) && input$addressFilter != "") {
      data <- data %>% filter(AddressBlockFound == input$addressFilter)
    }
    
    return(data)
  })
  
  # Reset filters
  observeEvent(input$resetFilters, {
    updateSelectInput(session, "yearFilter", selected = "All Years")
    updateSliderInput(session, "ageFilter", value = c(0, 100))
    updateSelectizeInput(session, "addressFilter", selected = "")
  })
  
  # ========== DEMOGRAPHICS VALUE BOXES ==========
  
  output$totalHomicides <- renderValueBox({
    valueBox(
      nrow(filtered_data()), 
      "Total Homicides", 
      icon = icon("skull-crossbones"),
      color = "red"
    )
  })
  
  output$avgAge <- renderValueBox({
    avg <- round(mean(filtered_data()$Age, na.rm = TRUE), 1)
    valueBox(
      ifelse(is.na(avg), "N/A", avg), 
      "Average Victim Age", 
      icon = icon("user"),
      color = "blue"
    )
  })
  
  output$mostCommonAge <- renderValueBox({
    age_counts <- filtered_data() %>%
      filter(!is.na(Age)) %>%
      count(Age) %>%
      arrange(desc(n))
    
    if (nrow(age_counts) > 0) {
      valueBox(
        age_counts$Age[1], 
        paste0("Most Common Age (", age_counts$n[1], " deaths)"),
        icon = icon("chart-bar"),
        color = "purple"
      )
    } else {
      valueBox("N/A", "Most Common Age", icon = icon("chart-bar"), color = "purple")
    }
  })
  
  # ========== TRENDS VALUE BOXES ==========
  
  output$trendTotalDeaths <- renderValueBox({
    valueBox(
      nrow(filtered_data()), 
      "Total Homicides", 
      icon = icon("skull-crossbones"),
      color = "red"
    )
  })
  
  output$deadliestMonth <- renderValueBox({
    if ("Month" %in% names(filtered_data())) {
      month_counts <- filtered_data() %>%
        filter(!is.na(Month)) %>%
        count(Month) %>%
        arrange(desc(n))
      
      if (nrow(month_counts) > 0) {
        valueBox(
          as.character(month_counts$Month[1]), 
          paste0("Deadliest Month (", month_counts$n[1], " deaths)"),
          icon = icon("calendar"),
          color = "orange"
        )
      } else {
        valueBox("N/A", "Deadliest Month", icon = icon("calendar"), color = "orange")
      }
    } else {
      valueBox("N/A", "Deadliest Month", icon = icon("calendar"), color = "orange")
    }
  })
  
  output$deadliestYear <- renderValueBox({
    year_counts <- filtered_data() %>%
      count(Year) %>%
      arrange(desc(n))
    
    if (nrow(year_counts) > 0) {
      valueBox(
        year_counts$Year[1], 
        paste0("Deadliest Year (", year_counts$n[1], " deaths)"),
        icon = icon("exclamation-triangle"),
        color = "yellow"
      )
    } else {
      valueBox("N/A", "Deadliest Year", icon = icon("exclamation-triangle"), color = "yellow")
    }
  })
  
  # ========== DEMOGRAPHICS PLOTS ==========
  
  output$ageDistPlot <- renderPlotly({
    data <- filtered_data() %>% filter(!is.na(Age))
    
    if (nrow(data) > 0) {
      plot_ly(data, x = ~Age, type = 'histogram', nbinsx = 30,
              marker = list(color = '#3c8dbc', line = list(color = 'white', width = 1))) %>%
        layout(xaxis = list(title = "Age"), yaxis = list(title = "Count"),
               bargap = 0.1)
    } else {
      plot_ly() %>% layout(title = "No data available")
    }
  })
  
  output$ageGroupPiePlot <- renderPlotly({
    data <- filtered_data() %>%
      filter(!is.na(AgeGroup)) %>%
      count(AgeGroup)
    
    if (nrow(data) > 0) {
      plot_ly(data, labels = ~AgeGroup, values = ~n, type = 'pie',
              marker = list(colors = c('#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b')),
              textinfo = 'label+percent',
              hovertemplate = paste('%{label}<br>Count: %{value}<br>Percent: %{percent}<extra></extra>')) %>%
        layout(showlegend = TRUE)
    } else {
      plot_ly() %>% layout(title = "No data available")
    }
  })
  
  output$genderPlot <- renderPlotly({
    if ("Gender" %in% names(filtered_data())) {
      data <- filtered_data() %>%
        filter(!is.na(Gender) & Gender != "" & Gender != " ") %>%
        count(Gender)
      
      if (nrow(data) > 0) {
        plot_ly(data, labels = ~Gender, values = ~n, type = 'pie',
                marker = list(colors = c('#3c8dbc', '#f39c12', '#dd4b39')),
                textinfo = 'label+percent',
                hovertemplate = paste('%{label}<br>Count: %{value}<br>Percent: %{percent}<extra></extra>')) %>%
          layout(showlegend = TRUE)
      } else {
        plot_ly() %>% layout(title = "No gender data available")
      }
    } else {
      plot_ly() %>% layout(title = "Gender column not found")
    }
  })
  
  output$weaponPiePlot <- renderPlotly({
    if ("WeaponCategory" %in% names(filtered_data())) {
      data <- filtered_data() %>%
        filter(!is.na(WeaponCategory)) %>%
        count(WeaponCategory) %>%
        arrange(desc(n))
      
      if (nrow(data) > 0) {
        plot_ly(data, labels = ~WeaponCategory, values = ~n, type = 'pie',
                marker = list(colors = c('#dd4b39', '#f39c12', '#605ca8', '#00a65a', '#3c8dbc')),
                textinfo = 'label+percent',
                hovertemplate = paste('%{label}<br>Count: %{value}<br>Percent: %{percent}<extra></extra>')) %>%
          layout(showlegend = TRUE)
      } else {
        plot_ly() %>% layout(title = "No weapon data available")
      }
    } else {
      plot_ly() %>% layout(title = "Weapon column not found")
    }
  })
  
  # ========== TRENDS PLOTS ==========
  
  output$yearlyBarPlot <- renderPlotly({
    data <- filtered_data() %>%
      count(Year)
    
    if (nrow(data) > 0) {
      plot_ly(data, x = ~Year, y = ~n, type = 'bar',
              marker = list(color = '#3c8dbc'),
              text = ~n, textposition = 'outside') %>%
        layout(xaxis = list(title = "Year"), yaxis = list(title = "Number of Homicides"))
    } else {
      plot_ly() %>% layout(title = "No data available")
    }
  })
  
  output$monthlyTrendPlot <- renderPlotly({
    if ("Month" %in% names(filtered_data())) {
      data <- filtered_data() %>%
        filter(!is.na(Month)) %>%
        count(MonthNum, Month) %>%
        arrange(MonthNum)
      
      if (nrow(data) > 0) {
        plot_ly(data, x = ~Month, y = ~n, type = 'bar',
                marker = list(color = '#f39c12'),
                text = ~n, textposition = 'outside') %>%
          layout(xaxis = list(title = "Month"), yaxis = list(title = "Number of Homicides"))
      } else {
        plot_ly() %>% layout(title = "No date data available")
      }
    } else {
      plot_ly() %>% layout(title = "Date column not found")
    }
  })
  
  output$timeSeriesPlot <- renderPlotly({
    if ("Date" %in% names(filtered_data())) {
      data <- filtered_data() %>%
        filter(!is.na(Date)) %>%
        mutate(YearMonth = floor_date(Date, "month")) %>%
        count(YearMonth)
      
      if (nrow(data) > 0) {
        plot_ly(data, x = ~YearMonth, y = ~n, type = 'scatter', mode = 'lines+markers',
                line = list(color = '#3c8dbc', width = 2),
                marker = list(size = 6, color = '#3c8dbc')) %>%
          layout(xaxis = list(title = "Date"), yaxis = list(title = "Number of Homicides"),
                 hovermode = 'x unified')
      } else {
        plot_ly() %>% layout(title = "No date data available")
      }
    } else {
      plot_ly() %>% layout(title = "Date column not found")
    }
  })
  
  output$weaponTrendPlot <- renderPlotly({
    if ("WeaponCategory" %in% names(filtered_data())) {
      data <- filtered_data() %>%
        filter(!is.na(WeaponCategory)) %>%
        count(Year, WeaponCategory)
      
      if (nrow(data) > 0) {
        plot_ly(data, x = ~Year, y = ~n, color = ~WeaponCategory,
                type = 'scatter', mode = 'lines+markers',
                colors = c('#dd4b39', '#f39c12', '#605ca8', '#00a65a', '#3c8dbc')) %>%
          layout(xaxis = list(title = "Year"), yaxis = list(title = "Number of Homicides"),
                 hovermode = 'x unified')
      } else {
        plot_ly() %>% layout(title = "No weapon data available")
      }
    } else {
      plot_ly() %>% layout(title = "Weapon column not found")
    }
  })
  
  # ========== DATA TABLE ==========
  
  output$dataTable <- renderDT({
    data <- filtered_data()
    
    # Build display data with available columns
    display_data <- data.frame(Year = data$Year, Age = data$Age)
    
    # Add Name column (no filter)
    if ("Name" %in% names(data)) {
      display_data$Name <- data$Name
    } else {
      display_data$Name <- NA
    }
    
    # Add Address Block Found column
    if ("AddressBlockFound" %in% names(data)) {
      display_data$AddressBlockFound <- data$AddressBlockFound
    } else {
      display_data$AddressBlockFound <- NA
    }
    
    # Add Case Closed column
    if ("CaseClosed" %in% names(data)) {
      display_data$CaseClosed <- data$CaseClosed
    } else {
      display_data$CaseClosed <- NA
    }
    
    # Rename columns for display
    names(display_data) <- c("Year", "Age", "Name", "Address Block Found", "Case Closed")
    
    # Create custom filter row (disable filter for Name column)
    datatable(display_data, 
              options = list(
                pageLength = 25, 
                scrollX = TRUE,
                dom = 'Bfrtip',
                buttons = c('copy', 'csv', 'excel'),
                columnDefs = list(
                  list(className = 'dt-center', targets = 0:1),
                  list(width = '10%', targets = 0),
                  list(width = '10%', targets = 1),
                  list(width = '20%', targets = 2),
                  list(width = '40%', targets = 3),
                  list(width = '20%', targets = 4)
                ),
                searchCols = list(
                  NULL,
                  NULL,
                  list(search = NULL, searchable = FALSE),
                  NULL,
                  NULL
                )
              ),
              filter = list(position = 'top', clear = TRUE, plain = FALSE),
              rownames = FALSE,
              class = 'cell-border stripe') %>%
      formatStyle('Name', cursor = 'default')
  })
}

# Run the App
shinyApp(ui, server)