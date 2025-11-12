library(shiny)
library(tidyverse)
library(lubridate)
library(DT)
library(ggplot2)
library(shinythemes)

data_file <- "all_homicides.csv"

ui <- fluidPage(
  theme = shinytheme("flatly"),
  titlePanel("Baltimore City Homicide Lists (Dashboard)"),
  sidebarLayout(
    sidebarPanel(
      helpText("Data source: chamspage.blogspot.com"),
      dateRangeInput("daterange", "Date range", start = "2021-01-01", end = Sys.Date()),
      selectInput("year", "Year (or All)", choices = c("All"), selected = "All"),
      textInput("search", "Search (name/location/text)", ""),
      width = 3
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Overview",
                 fluidRow(
                   column(6, plotOutput("by_year_plot")),
                   column(6, plotOutput("by_month_plot"))
                 ),
                 hr(),
                 DTOutput("table")
        ),
        tabPanel("Raw Data", DTOutput("raw_table")),
        tabPanel("Summary", verbatimTextOutput("summary"))
      )
    )
  )
)

server <- function(input, output, session) {
  if (!file.exists(data_file)) stop(paste0("Data file not found: ", data_file, ". Run the scraper first."))
  
  dat <- reactive({
    df <- read_csv(data_file, show_col_types = FALSE)
    date_col_candidates <- names(df)[str_detect(names(df), regex("date", ignore_case = TRUE))]
    if ("date_parsed" %in% names(df)) {
      df <- df %>% mutate(date_parsed = as.Date(date_parsed, origin = "1970-01-01"))
    } else if (length(date_col_candidates) >= 1) {
      candidate <- date_col_candidates[1]
      df <- df %>% mutate(date_parsed = parse_date_time(.data[[candidate]], orders = c("mdy", "BdY", "Y-m-d", "dby", "ymd"), truncated = 3))
      df <- df %>% mutate(date_parsed = as.Date(date_parsed))
    } else {
      df$date_parsed <- as.Date(NA)
    }
    
    if (!"year" %in% names(df)) {
      df <- df %>% mutate(year = if_else(!is.na(date_parsed), as.character(year(date_parsed)), NA_character_))
    } else {
      df <- df %>% mutate(year = as.character(.data[["year"]]))
    }
    
    required_cols <- c("raw_line", "summary", "name", "age", "source_url")
    for (col in required_cols) {
      if (!col %in% names(df)) df[[col]] <- NA_character_
    }
    
    df <- df %>% mutate(across(where(is.character), ~ str_trim(.x)))
    df
  })
  
  years <- reactive({
    yrs <- dat() %>% pull(year)
    yrs <- unique(na.omit(yrs))
    yrs_sorted <- sort(as.integer(yrs), decreasing = FALSE)
    yrs_sorted <- as.character(yrs_sorted)
    c("All", yrs_sorted)
  })
  
  observe({ updateSelectInput(session, "year", choices = years(), selected = "All") })
  
  filtered <- reactive({
    df <- dat()
    if (!is.null(input$year) && input$year != "All") df <- df %>% filter(!is.na(year) & year == input$year)
    if (!is.null(input$daterange) && !all(is.na(df$date_parsed))) {
      rng <- input$daterange
      df <- df %>% filter(!is.na(date_parsed) & date_parsed >= rng[1] & date_parsed <= rng[2])
    }
    if (!is.null(input$search) && str_trim(input$search) != "") {
      s <- str_to_lower(input$search)
      df <- df %>% filter(if_any(everything(), ~ str_detect(str_to_lower(as.character(.x)), fixed(s))))
    }
    df
  })
  
  output$by_year_plot <- renderPlot({
    df <- dat()
    if (!all(is.na(df$date_parsed))) {
      plot_df <- df %>% filter(!is.na(date_parsed)) %>% mutate(y = year(date_parsed)) %>% count(y)
      ggplot(plot_df, aes(x = factor(y), y = n)) + geom_col() + labs(x = "Year", y = "Count") + theme_minimal()
    } else if ("year" %in% names(df) && any(!is.na(df$year))) {
      plot_df <- df %>% filter(!is.na(year)) %>% count(year)
      ggplot(plot_df, aes(x = factor(year), y = n)) + geom_col() + labs(x = "Year", y = "Count") + theme_minimal()
    } else {
      plot.new(); title("No date/year data available")
    }
  })
  
  output$by_month_plot <- renderPlot({
    df <- dat()
    if (all(is.na(df$date_parsed))) { plot.new(); title("No parsed dates for monthly plot"); return() }
    dfm <- df %>% filter(!is.na(date_parsed)) %>% mutate(month = floor_date(date_parsed, "month")) %>% count(month) %>% arrange(month)
    ggplot(dfm, aes(x = month, y = n)) + geom_col() + labs(x = "Month", y = "Homicides") + theme_minimal()
  })
  
  output$table <- renderDT({
    df <- filtered()
    preferred <- c("date_parsed", "year", "name", "age", "summary", "source_url", "raw_line")
    avail <- intersect(preferred, names(df))
    display_df <- df %>% select(all_of(avail))
    if ("date_parsed" %in% names(display_df)) display_df <- display_df %>% mutate(date_parsed = as.character(date_parsed))
    datatable(display_df, options = list(pageLength = 10, scrollX = TRUE))
  })
  
  output$raw_table <- renderDT({ datatable(dat(), options = list(pageLength = 20, scrollX = TRUE)) })
  
  output$summary <- renderPrint({
    df <- dat()
    cat("Rows:", nrow(df), "\n")
    yrs <- sort(unique(na.omit(df$year)))
    cat("Years present:", ifelse(length(yrs) == 0, "None", paste(yrs, collapse = ", ")), "\n")
    cat("Missing parsed dates:", sum(is.na(df$date_parsed)), "\n")
    if ("raw_line" %in% names(df)) cat("Duplicate raw lines:", nrow(df) - n_distinct(df$raw_line), "\n") else cat("raw_line column not present\n")
    cat("\nHint: If you see parsing issues, run `problems()` on the CSV read.\n")
  })
}

shinyApp(ui, server)
