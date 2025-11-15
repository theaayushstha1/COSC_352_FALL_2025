# app.R
# Baltimore City Homicides Dashboard (2021–2025)
# Uses R + Shiny + rvest + tidyverse-style tools

library(shiny)
library(rvest)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)
library(DT)
library(ggplot2)
library(purrr)
library(tibble)

# -----------------------------
# 1. Data scraping & cleaning
# -----------------------------

homicide_urls <- tibble::tibble(
  year = c(2021, 2022, 2023, 2024, 2025),
  url  = c(
    "https://chamspage.blogspot.com/2021/",
    "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
    "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
    "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
    "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
  )
)

scrape_one_year <- function(year, url) {
  message("Scraping year ", year, " from ", url)
  
  page <- read_html(url)
  
  # The blog usually stores the homicide list in a table element.
  tables <- html_elements(page, "table")
  if (length(tables) == 0) {
    stop("No HTML tables found for year ", year, ". HTML structure may have changed.")
  }
  
  # Often the first table is the list we want.
  df_raw <- html_table(tables, fill = TRUE)[[1]]
  
  # Remove completely empty columns
  df_raw <- df_raw[, colSums(is.na(df_raw) | df_raw == "") < nrow(df_raw), drop = FALSE]
  
  # Remove header / junk rows: keep rows where first column looks like "001", "002", "XXX", "???", etc.
  first_col <- df_raw[[1]]
  keep <- str_detect(first_col, "^[0-9?Xx]{3}") | str_detect(first_col, "^[0-9]{1,3}$")
  df <- df_raw[keep, , drop = FALSE]
  
  # Standardize to at least 10 columns by padding with NA
  if (ncol(df) < 10) {
    df <- cbind(df, matrix(NA_character_, nrow = nrow(df), ncol = 10 - ncol(df)))
  }
  
  # Make sure character columns are character, not factors
  df[] <- lapply(df, \(x) if (is.factor(x)) as.character(x) else x)
  
  out <- tibble::tibble(
    year        = year,
    no          = df[[1]],
    date_str    = df[[2]],
    name        = df[[3]],
    age_raw     = df[[4]],
    address     = df[[5]],
    block_found = df[[6]],
    notes       = df[[7]],
    history     = df[[8]],
    camera      = df[[9]],
    case_closed = df[[10]]
  )
  
  # Clean numeric age
  out <- out |>
    mutate(
      age = suppressWarnings(as.numeric(str_extract(age_raw, "\\d+"))),
      # Dates are often like "01/09/25"; use mdy and let lubridate handle 2-digit year
      date = suppressWarnings(mdy(date_str)),
      month = floor_date(date, "month"),
      closed_flag = str_detect(str_to_lower(paste(case_closed, notes)), "closed"),
      camera_flag = str_detect(str_to_lower(paste(camera, notes)), "camera"),
      safe_streets = str_detect(str_to_lower(notes), "safe streets")
    )
  
  out
}

load_all_homicides <- function() {
  purrr::map2_dfr(homicide_urls$year, homicide_urls$url, scrape_one_year) |>
    # Some rows are "maybes" or weird; keep where we at least have a name or address
    filter(!is.na(name) | !is.na(address))
}

# Load data once at app startup
homicides <- load_all_homicides()

# Precompute global ranges for UI
age_min <- min(homicides$age, na.rm = TRUE)
age_max <- max(homicides$age, na.rm = TRUE)

# -----------------------------
# 2. Shiny UI
# -----------------------------

ui <- fluidPage(
  titlePanel("Baltimore City Homicides Dashboard (2021–2025)"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput(
        "year_filter",
        "Year",
        choices = c("All years", sort(unique(homicides$year))),
        selected = "All years"
      ),
      sliderInput(
        "age_filter",
        "Age range",
        min = age_min,
        max = age_max,
        value = c(age_min, age_max),
        step = 1
      ),
      checkboxInput("closed_only", "Closed cases only", value = FALSE),
      checkboxInput("camera_only", "Cases near a surveillance camera", value = FALSE),
      checkboxInput("safe_only", "Safe Streets catchment area only", value = FALSE),
      
      hr(),
      helpText(
        "Data source: chamspage.blogspot.com homicide lists for 2021–2025."
      )
    ),
    
    mainPanel(
      width = 9,
      tabsetPanel(
        tabPanel(
          "Overview",
          br(),
          fluidRow(
            column(
              4,
              wellPanel(
                h4("Total homicides (filtered)"),
                textOutput("total_cases"),
                h5("Closed cases (filtered)"),
                textOutput("total_closed")
              )
            ),
            column(
              4,
              wellPanel(
                h4("Median age (filtered)"),
                textOutput("median_age"),
                h5("Cases in Safe Streets areas"),
                textOutput("total_safe")
              )
            ),
            column(
              4,
              wellPanel(
                h4("Camera-related cases"),
                textOutput("total_camera"),
                h5("Years covered"),
                textOutput("years_span")
              )
            )
          ),
          br(),
          h3("Monthly homicide trend"),
          plotOutput("monthly_trend", height = "350px")
        ),
        
        tabPanel(
          "Age distribution",
          br(),
          plotOutput("age_hist", height = "350px")
        ),
        
        tabPanel(
          "Case closure status",
          br(),
          plotOutput("closure_plot", height = "350px")
        ),
        
        tabPanel(
          "Data table",
          br(),
          DTOutput("table")
        )
      )
    )
  )
)

# -----------------------------
# 3. Shiny server
# -----------------------------

server <- function(input, output, session) {
  
  filtered_data <- reactive({
    df <- homicides
    
    # Year filter
    if (input$year_filter != "All years") {
      df <- df |> filter(year == as.integer(input$year_filter))
    }
    
    # Age filter
    df <- df |>
      filter(is.na(age) | (age >= input$age_filter[1] & age <= input$age_filter[2]))
    
    # Closed only
    if (isTRUE(input$closed_only)) {
      df <- df |> filter(closed_flag)
    }
    
    # Camera only
    if (isTRUE(input$camera_only)) {
      df <- df |> filter(camera_flag)
    }
    
    # Safe Streets only
    if (isTRUE(input$safe_only)) {
      df <- df |> filter(safe_streets)
    }
    
    df
  })
  
  # Summary cards
  output$total_cases <- renderText({
    nrow(filtered_data())
  })
  
  output$total_closed <- renderText({
    sum(filtered_data()$closed_flag, na.rm = TRUE)
  })
  
  output$median_age <- renderText({
    med <- median(filtered_data()$age, na.rm = TRUE)
    if (is.na(med)) "N/A" else round(med, 1)
  })
  
  output$total_safe <- renderText({
    sum(filtered_data()$safe_streets, na.rm = TRUE)
  })
  
  output$total_camera <- renderText({
    sum(filtered_data()$camera_flag, na.rm = TRUE)
  })
  
  output$years_span <- renderText({
    yrs <- sort(unique(filtered_data()$year))
    paste(yrs, collapse = ", ")
  })
  
  # Plots
  output$monthly_trend <- renderPlot({
    df <- filtered_data() |>
      filter(!is.na(date)) |>
      mutate(month = floor_date(date, "month")) |>
      count(month, year)
    
    if (nrow(df) == 0) return(NULL)
    
    ggplot(df, aes(x = month, y = n, color = factor(year), group = year)) +
      geom_line() +
      geom_point() +
      labs(
        x = "Month",
        y = "Number of homicides",
        color = "Year"
      ) +
      theme_minimal()
  })
  
  output$age_hist <- renderPlot({
    df <- filtered_data() |>
      filter(!is.na(age))
    
    if (nrow(df) == 0) return(NULL)
    
    ggplot(df, aes(x = age)) +
      geom_histogram(binwidth = 5) +
      labs(
        x = "Age",
        y = "Count",
        title = "Age distribution of homicide victims (filtered)"
      ) +
      theme_minimal()
  })
  
  output$closure_plot <- renderPlot({
    df <- filtered_data() |>
      mutate(
        closed = ifelse(closed_flag, "Closed", "Not closed")
      ) |>
      count(year, closed)
    
    if (nrow(df) == 0) return(NULL)
    
    ggplot(df, aes(x = factor(year), y = n, fill = closed)) +
      geom_col(position = "dodge") +
      labs(
        x = "Year",
        y = "Number of cases",
        fill = "Case status",
        title = "Closed vs not-closed cases by year (filtered)"
      ) +
      theme_minimal()
  })
  
  # Data table
  output$table <- renderDT({
    df <- filtered_data() |>
      select(
        Year = year,
        No = no,
        Date = date_str,
        Name = name,
        Age = age,
        Address = address,
        Block = block_found,
        Notes = notes,
        CameraInfo = camera,
        CaseClosed = case_closed
      )
    
    datatable(
      df,
      options = list(pageLength = 15, scrollX = TRUE)
    )
  })
}

shinyApp(ui, server)
