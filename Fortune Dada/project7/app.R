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
      # Replaced selectInput with textInput for year
      textInput("year_input", "Year (e.g., 2023, or leave blank for all)", ""),
      textInput("search", "Search (name/location/text)", ""),
      # Added Action Button for filtering
      actionButton("apply_filters", "Apply Filters", icon = icon("filter")), 
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
  
  # Load and clean data once (reactive)
  dat <- reactive({
    if (!file.exists(data_file)) stop(paste0("Data file not found: ", data_file, ". Run the scraper first."))
    
    df <- read_csv(data_file, show_col_types = FALSE) %>%
      # Rename and convert columns from scrape.R output
      rename(Date = date_parsed, Year = year, Name = name, Location = location, Notes = raw_line) %>%
      mutate(
        Date = as.Date(Date),
        Year = as.integer(Year),
        Age = as.integer(age), # Use the 'age' column from scraper output
        Month = floor_date(Date, "month")
      ) %>%
      # Filter for data starting 2021 to exclude unexpected historical data
      filter(!is.na(Date) & Year >= 2021) 
    
    # Select and standardize final columns for use
    df %>% 
      select(Date, Year, Name, Age, Location, Notes, Month, source, date_raw)
  })
  
  # Reactive block for filtering, tied to the "Apply Filters" action button
  filtered_data <- eventReactive(input$apply_filters, {
    df <- dat()
    
    # 1. Date Range Filter
    rng <- input$daterange
    if (!is.null(rng) && !all(is.na(df$Date))) {
      df <- df %>% filter(Date >= rng[1] & Date <= rng[2])
    }
    
    # 2. Year Filter (using textInput)
    year_input <- str_trim(input$year_input)
    if (year_input != "") {
      req_years <- str_split(year_input, pattern = ",\\s*")[[1]] %>% 
        as.integer() %>% 
        na.omit()
      
      if (length(req_years) > 0) {
        df <- df %>% filter(Year %in% req_years)
      }
    }
    
    # 3. Search Filter
    s <- str_to_lower(str_trim(input$search))
    if (s != "") {
      df <- df %>% filter(
        str_to_lower(Name) %>% str_detect(fixed(s)) |
          str_to_lower(Location) %>% str_detect(fixed(s)) |
          str_to_lower(Notes) %>% str_detect(fixed(s))
      )
    }
    
    df
  }, ignoreNULL = FALSE)
  
  # --- Outputs ---
  
  output$by_year_plot <- renderPlot({
    df <- filtered_data()
    if (nrow(df) == 0) { plot.new(); title(main = "No data to display"); return() }
    
    plot_df <- df %>% count(Year)
    ggplot(plot_df, aes(x = factor(Year), y = n)) + 
      geom_col(fill = "steelblue") + 
      labs(x = "Year", y = "Count") + 
      theme_minimal()
  })
  
  output$by_month_plot <- renderPlot({
    df <- filtered_data()
    if (nrow(df) == 0 || all(is.na(df$Month))) { plot.new(); title(main = "No data to display"); return() }
    
    dfm <- df %>% count(Month) %>% arrange(Month)
    ggplot(dfm, aes(x = Month, y = n)) + 
      geom_col(fill = "tomato") + 
      labs(x = "Month", y = "Homicides") + 
      scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  output$table <- renderDT({
    df <- filtered_data()
    display_df <- df %>% select(Date, Year, Name, Age, Location, Notes)
    datatable(display_df, options = list(pageLength = 10, scrollX = TRUE))
  })
  
  output$raw_table <- renderDT({ 
    datatable(dat(), options = list(pageLength = 20, scrollX = TRUE)) 
  })
  
  output$summary <- renderPrint({
    df <- dat()
    cat("Rows in full dataset (2021+):", nrow(df), "\n")
    yrs <- sort(unique(na.omit(df$Year)))
    cat("Years present:", ifelse(length(yrs) == 0, "None", paste(yrs, collapse = ", ")), "\n")
    cat("Missing parsed dates:", sum(is.na(df$Date)), "\n")
  })
}

shinyApp(ui, server)