library(shiny)
library(shinydashboard)
library(rvest)
library(dplyr)
library(lubridate)
library(janitor)
library(ggplot2)
library(DT)
library(stringr)
library(httr)

# Function to scrape Baltimore homicide data
scrape_year <- function(year) {
  url <- if (year == 2021) {
    "http://chamspage.blogspot.com/2021/"
  } else {
    paste0("http://chamspage.blogspot.com/", year, "/01/", year, "-baltimore-city-homicide-list.html")
  }
  
  tryCatch({
    message(paste("Scraping", year, "..."))
    page <- read_html(url, timeout(15))
    tables <- page %>% html_table(fill = TRUE)
    
    for (tbl in tables) {
      cols <- tolower(colnames(tbl))
      if (any(grepl("date", cols)) && any(grepl("name", cols))) {
        df <- tbl %>%
          clean_names() %>%
          mutate(year = year)
        message(paste("✓ Found", nrow(df), "records for", year))
        return(df)
      }
    }
    message(paste("✗ No data table found for", year))
    return(NULL)
  }, error = function(e) {
    message(paste("✗ Error scraping", year, ":", e$message))
    return(NULL)
  })
}

# Scrape all years
message("\n=== Starting Data Collection ===")
data_list <- lapply(2021:2025, scrape_year)
data_list <- Filter(Negate(is.null), data_list)

if (length(data_list) == 0) {
  message("ERROR: No data scraped. Using sample data instead.")
  all_data <- data.frame(
    year = sample(2021:2025, 150, replace = TRUE),
    date_died = seq(as.Date("2021-01-01"), by = "3 days", length.out = 150),
    name = paste("Victim", 1:150),
    age = sample(15:75, 150, replace = TRUE),
    address = paste(sample(100:9999, 150), "Block St"),
    notes = sample(c("shooting death", "stabbing", "blunt force", "other"), 150, replace = TRUE),
    surveillance = sample(c("Camera", "None", NA), 150, replace = TRUE),
    case_closed = sample(c("Closed", "Open"), 150, replace = TRUE)
  )
} else {
  all_data <- bind_rows(data_list)
  message(paste("\n✓ Total records loaded:", nrow(all_data)))
}

# Clean and process data
all_data <- all_data %>%
  mutate(
    age_numeric = if("age" %in% names(.)) as.numeric(str_extract(age, "\\d+")) else NA_real_,
    date_died = if("date_died" %in% names(.)) mdy(date_died) else 
                 if("date" %in% names(.)) mdy(date) else NA,
    month = floor_date(date_died, "month"),
    has_camera = if("surveillance" %in% names(.)) {
      !is.na(surveillance) & !grepl("none|no", tolower(surveillance)) & surveillance != ""
    } else FALSE,
    is_closed = if("case_closed" %in% names(.)) grepl("closed", tolower(case_closed)) else FALSE,
    cause = if("notes" %in% names(.)) {
      case_when(
        grepl("shoot", tolower(notes)) ~ "Shooting",
        grepl("stab", tolower(notes)) ~ "Stabbing",
        grepl("blunt|struck", tolower(notes)) ~ "Blunt Force",
        TRUE ~ "Other"
      )
    } else "Unknown"
  )

message("✓ Data processing complete\n")

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Baltimore Homicides 2021-2025"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Data Table", tabName = "data", icon = icon("table")),
      menuItem("Analytics", tabName = "analytics", icon = icon("chart-bar"))
    ),
    hr(),
    checkboxGroupInput("year_filter", "Years:",
                       choices = sort(unique(all_data$year)),
                       selected = sort(unique(all_data$year))),
    sliderInput("age_range", "Age Range:",
                min = 0, max = 100, value = c(0, 100)),
    textInput("keyword", "Search:", "")
  ),
  
  dashboardBody(
    tabItems(
      tabItem(tabName = "dashboard",
        fluidRow(
          valueBoxOutput("total"),
          valueBoxOutput("closure"),
          valueBoxOutput("avg_age")
        ),
        fluidRow(
          box(title = "Homicides by Year", plotOutput("year_plot"), width = 6),
          box(title = "Homicides by Month", plotOutput("month_plot"), width = 6)
        ),
        fluidRow(
          box(title = "By Cause", plotOutput("cause_plot"), width = 6),
          box(title = "Camera Impact", plotOutput("camera_plot"), width = 6)
        )
      ),
      
      tabItem(tabName = "data",
        box(title = "Homicide Records", width = 12,
            DTOutput("table"))
      ),
      
      tabItem(tabName = "analytics",
        box(title = "Camera Surveillance Analysis", width = 12,
            verbatimTextOutput("camera_stats")),
        box(title = "Cause Analysis", width = 12,
            verbatimTextOutput("cause_stats"))
      )
    )
  )
)

# Server
server <- function(input, output) {
  
  filtered <- reactive({
    data <- all_data %>%
      filter(
        year %in% input$year_filter,
        (age_numeric >= input$age_range[1] & age_numeric <= input$age_range[2]) | is.na(age_numeric)
      )
    
    if (input$keyword != "") {
      kw <- tolower(input$keyword)
      data <- data %>%
        filter(
          if("address" %in% names(.)) grepl(kw, tolower(address)) else FALSE |
          if("notes" %in% names(.)) grepl(kw, tolower(notes)) else FALSE |
          if("name" %in% names(.)) grepl(kw, tolower(name)) else FALSE
        )
    }
    data
  })
  
  output$total <- renderValueBox({
    valueBox(nrow(filtered()), "Total Homicides", icon = icon("list"), color = "red")
  })
  
  output$closure <- renderValueBox({
    rate <- mean(filtered()$is_closed, na.rm = TRUE) * 100
    valueBox(paste0(round(rate, 1), "%"), "Closed", icon = icon("check"), color = "green")
  })
  
  output$avg_age <- renderValueBox({
    valueBox(round(mean(filtered()$age_numeric, na.rm = TRUE), 1), "Avg Age", 
             icon = icon("user"), color = "blue")
  })
  
  output$year_plot <- renderPlot({
    filtered() %>%
      count(year) %>%
      ggplot(aes(x = factor(year), y = n, fill = factor(year))) +
      geom_col() +
      labs(x = "Year", y = "Count") +
      theme_minimal(base_size = 14) +
      theme(legend.position = "none")
  })
  
  output$month_plot <- renderPlot({
    filtered() %>%
      filter(!is.na(month)) %>%
      count(month) %>%
      ggplot(aes(x = month, y = n)) +
      geom_line(color = "steelblue", size = 1.2) +
      geom_point(color = "steelblue", size = 3) +
      labs(x = "Month", y = "Count") +
      theme_minimal(base_size = 14)
  })
  
  output$cause_plot <- renderPlot({
    filtered() %>%
      count(cause) %>%
      ggplot(aes(x = reorder(cause, n), y = n, fill = cause)) +
      geom_col() +
      coord_flip() +
      labs(x = "", y = "Count") +
      theme_minimal(base_size = 14) +
      theme(legend.position = "none")
  })
  
  output$camera_plot <- renderPlot({
    filtered() %>%
      group_by(has_camera) %>%
      summarise(rate = mean(is_closed, na.rm = TRUE) * 100, .groups = "drop") %>%
      mutate(status = ifelse(has_camera, "With Camera", "No Camera")) %>%
      ggplot(aes(x = status, y = rate, fill = status)) +
      geom_col() +
      labs(x = "", y = "Closure Rate (%)") +
      theme_minimal(base_size = 14) +
      theme(legend.position = "none")
  })
  
  output$table <- renderDT({
    cols <- intersect(c("year", "date_died", "name", "age", "address", "notes", "surveillance", "case_closed"),
                      names(filtered()))
    filtered() %>%
      select(all_of(cols)) %>%
      datatable(options = list(pageLength = 25, scrollX = TRUE), rownames = FALSE)
  })
  
  output$camera_stats <- renderText({
    with_cam <- filtered() %>% filter(has_camera)
    without_cam <- filtered() %>% filter(!has_camera)
    
    paste0(
      "CAMERA SURVEILLANCE IMPACT\n",
      "="  %>% rep(50) %>% paste(collapse = ""), "\n\n",
      "WITH Camera:\n",
      "  Cases: ", nrow(with_cam), "\n",
      "  Closed: ", sum(with_cam$is_closed), "\n",
      "  Rate: ", round(mean(with_cam$is_closed) * 100, 2), "%\n",
      "  Avg Age: ", round(mean(with_cam$age_numeric, na.rm = TRUE), 1), "\n\n",
      "WITHOUT Camera:\n",
      "  Cases: ", nrow(without_cam), "\n",
      "  Closed: ", sum(without_cam$is_closed), "\n",
      "  Rate: ", round(mean(without_cam$is_closed) * 100, 2), "%\n",
      "  Avg Age: ", round(mean(without_cam$age_numeric, na.rm = TRUE), 1)
    )
  })
  
  output$cause_stats <- renderText({
    stats <- filtered() %>%
      group_by(cause) %>%
      summarise(
        total = n(),
        closed = sum(is_closed),
        rate = mean(is_closed) * 100,
        avg_age = mean(age_numeric, na.rm = TRUE),
        .groups = "drop"
      )
    
    result <- "CAUSE vs CLOSURE ANALYSIS\n"
    result <- paste0(result, "=" %>% rep(50) %>% paste(collapse = ""), "\n\n")
    
    for (i in 1:nrow(stats)) {
      result <- paste0(result, stats$cause[i], ": ",
                      "Total=", stats$total[i], " | ",
                      "Closed=", stats$closed[i], " | ",
                      "Rate=", round(stats$rate[i], 1), "% | ",
                      "Avg Age=", round(stats$avg_age[i], 1), "\n")
    }
    result
  })
}

shinyApp(ui, server)
