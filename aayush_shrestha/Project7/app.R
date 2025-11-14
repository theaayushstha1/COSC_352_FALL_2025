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

# Scrape function
scrape_year <- function(year) {
  url <- if (year == 2021) {
    "http://chamspage.blogspot.com/2021/"
  } else {
    paste0("http://chamspage.blogspot.com/", year, "/01/", year, "-baltimore-city-homicide-list.html")
  }
  
  tryCatch({
    message(paste("Scraping", year, "from", url))
    
    response <- GET(url, timeout(20))
    if (status_code(response) != 200) {
      message(paste("Failed to fetch", year, "- Status:", status_code(response)))
      return(NULL)
    }
    
    page <- read_html(content(response, "text"))
    tables <- page %>% html_table(fill = TRUE)
    
    if (length(tables) == 0) {
      message(paste("No tables found for", year))
      return(NULL)
    }
    
    for (i in seq_along(tables)) {
      tbl <- tables[[i]]
      if (nrow(tbl) < 5 || ncol(tbl) < 5) next
      
      cols <- tolower(colnames(tbl))
      if (any(grepl("date", cols)) && any(grepl("name|victim", cols))) {
        df <- tbl %>%
          clean_names() %>%
          mutate(year = year) %>%
          filter(!is.na(year))
        
        message(paste("SUCCESS:", nrow(df), "records from", year))
        return(df)
      }
    }
    
    message(paste("No valid table found for", year))
    return(NULL)
    
  }, error = function(e) {
    message(paste("ERROR scraping", year, ":", e$message))
    return(NULL)
  })
}

# Load data
message("\n========== STARTING DATA COLLECTION ==========")
data_list <- list()
for (yr in 2021:2025) {
  result <- scrape_year(yr)
  if (!is.null(result)) {
    data_list[[as.character(yr)]] <- result
  }
  Sys.sleep(1)  # Be polite to the server
}

if (length(data_list) == 0) {
  message("WARNING: No data scraped! Using sample data.")
  all_data <- data.frame(
    no = 1:100,
    date_died = seq(as.Date("2021-01-01"), by = "week", length.out = 100),
    name = paste("Person", 1:100),
    age = sample(18:80, 100, replace = TRUE),
    address = paste(sample(1000:9999, 100), "Block St"),
    notes = sample(c("shooting death", "stabbing", "blunt force trauma", "other"), 100, replace = TRUE),
    surveillance = sample(c("Camera present", "None", NA), 100, replace = TRUE, prob = c(0.3, 0.5, 0.2)),
    case_closed = sample(c("Closed", "Open", "Pending"), 100, replace = TRUE),
    year = sample(2021:2025, 100, replace = TRUE)
  )
} else {
  all_data <- bind_rows(data_list)
  message(paste("\n========== SUCCESS: Loaded", nrow(all_data), "total records ==========\n"))
}

# Process data
all_data <- all_data %>%
  mutate(
    age_numeric = as.numeric(gsub("[^0-9]", "", as.character(age))),
    date_died = tryCatch(mdy(date_died), error = function(e) NA),
    month = floor_date(date_died, "month"),
    has_camera = !is.na(surveillance) & !grepl("none|no", tolower(as.character(surveillance))),
    is_closed = grepl("closed", tolower(as.character(case_closed))),
    cause = case_when(
      grepl("shoot", tolower(as.character(notes))) ~ "Shooting",
      grepl("stab", tolower(as.character(notes))) ~ "Stabbing",
      grepl("blunt|struck", tolower(as.character(notes))) ~ "Blunt Force",
      TRUE ~ "Other"
    )
  )

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
    sliderInput("age_range", "Age Range:", min = 0, max = 100, value = c(0, 100)),
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
        box(title = "Homicide Records", width = 12, DTOutput("table"))
      ),
      tabItem(tabName = "analytics",
        box(title = "Camera Analysis", width = 12, verbatimTextOutput("camera_stats")),
        box(title = "Cause Analysis", width = 12, verbatimTextOutput("cause_stats"))
      )
    )
  )
)

# Server
server <- function(input, output) {
  filtered <- reactive({
    req(input$year_filter)
    data <- all_data %>%
      filter(year %in% input$year_filter,
             (age_numeric >= input$age_range[1] & age_numeric <= input$age_range[2]) | is.na(age_numeric))
    
    if (input$keyword != "") {
      kw <- tolower(input$keyword)
      data <- data %>% filter(grepl(kw, tolower(paste(name, address, notes))))
    }
    data
  })
  
  output$total <- renderValueBox({
    valueBox(nrow(filtered()), "Total", icon = icon("list"), color = "red")
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
    filtered() %>% count(year) %>%
      ggplot(aes(x = factor(year), y = n, fill = factor(year))) +
      geom_col() + labs(x = "Year", y = "Count") +
      theme_minimal(base_size = 14) + theme(legend.position = "none")
  })
  
  output$month_plot <- renderPlot({
    filtered() %>% filter(!is.na(month)) %>% count(month) %>%
      ggplot(aes(x = month, y = n)) +
      geom_line(color = "steelblue", size = 1.2) +
      geom_point(color = "steelblue", size = 3) +
      labs(x = "Month", y = "Count") + theme_minimal(base_size = 14)
  })
  
  output$cause_plot <- renderPlot({
    filtered() %>% count(cause) %>%
      ggplot(aes(x = reorder(cause, n), y = n, fill = cause)) +
      geom_col() + coord_flip() + labs(x = "", y = "Count") +
      theme_minimal(base_size = 14) + theme(legend.position = "none")
  })
  
  output$camera_plot <- renderPlot({
    filtered() %>% group_by(has_camera) %>%
      summarise(rate = mean(is_closed, na.rm = TRUE) * 100, .groups = "drop") %>%
      mutate(status = ifelse(has_camera, "With Camera", "No Camera")) %>%
      ggplot(aes(x = status, y = rate, fill = status)) +
      geom_col() + labs(x = "", y = "Closure Rate (%)") +
      theme_minimal(base_size = 14) + theme(legend.position = "none")
  })
  
  output$table <- renderDT({
    filtered() %>% select(any_of(c("year", "date_died", "name", "age", "address", "notes"))) %>%
      datatable(options = list(pageLength = 25, scrollX = TRUE), rownames = FALSE)
  })
  
  output$camera_stats <- renderText({
    with_cam <- filtered() %>% filter(has_camera)
    without_cam <- filtered() %>% filter(!has_camera)
    paste0(
      "WITH Camera: ", nrow(with_cam), " cases, ",
      round(mean(with_cam$is_closed) * 100, 1), "% closed\n",
      "WITHOUT Camera: ", nrow(without_cam), " cases, ",
      round(mean(without_cam$is_closed) * 100, 1), "% closed"
    )
  })
  
  output$cause_stats <- renderText({
    stats <- filtered() %>% group_by(cause) %>%
      summarise(total = n(), closed = sum(is_closed), rate = mean(is_closed) * 100, .groups = "drop")
    paste(apply(stats, 1, function(x) paste(x[1], ": ", x[2], " cases, ", round(as.numeric(x[4]), 1), "% closed")), collapse = "\n")
  })
}

shinyApp(ui, server)
