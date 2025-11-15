# app.R
# Baltimore Homicide Lists - Simple Table Parser with Separate Year Plots

library(shiny)
library(dplyr)
library(ggplot2)
library(rvest)
library(lubridate)
library(DT)
library(plotly)

# ----------- SCRAPER -----------

load_all_years <- function() {
  urls <- c(
    "https://chamspage.blogspot.com/2021/",
    "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
    "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
    "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
    "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
  )

  all_data <- list()
  
  for (url in urls) {
    Sys.sleep(1)
    
    page <- tryCatch(read_html(url), error = function(e) NULL)
    if (is.null(page)) next
    
    tables <- html_table(page, fill = TRUE)
    if (length(tables) == 0) next
    
    # Get the largest table
    tbl <- tables[[which.max(sapply(tables, nrow))]]
    
    # Basic cleaning
    names(tbl) <- tolower(gsub("[^a-z0-9]", "_", names(tbl)))
    
    # Find date column (first column typically)
    date_col <- names(tbl)[1]
    
    tbl$source_url <- url
    all_data[[url]] <- tbl
  }
  
  bind_rows(all_data)
}

# ----------- SHINY APP -----------

ui <- fluidPage(
  titlePanel("Baltimore City Homicides - By Year"),
  
  sidebarLayout(
    sidebarPanel(
      actionButton("reload", "Load Data", class = "btn-primary"),
      width = 3
    ),

    mainPanel(
      tabsetPanel(
        tabPanel("Daily Plots", uiOutput("daily_plots")),
        tabPanel("Monthly Plots", uiOutput("monthly_plots")),
        tabPanel("Table", DTOutput("table"))
      )
    )
  )
)

server <- function(input, output, session) {

  data <- reactiveVal(NULL)

  observeEvent(input$reload, {
    showModal(modalDialog("Loading data...", footer = NULL))
    
    raw <- load_all_years()
    
    # Parse dates from first column
    raw$date <- parse_date_time(raw[[1]], orders = c("mdy", "m/d/y"), quiet = TRUE)
    raw$year <- year(raw$date)
    
    # Filter valid dates
    clean <- raw[!is.na(raw$date), ]
    
    data(clean)
    removeModal()
    
    if (nrow(clean) > 0) {
      showModal(modalDialog(paste("Loaded", nrow(clean), "records"), footer = modalButton("OK")))
    }
  })

  output$daily_plots <- renderUI({
    dat <- data()
    if (is.null(dat)) return(p("Click Load Data"))
    
    years <- sort(unique(dat$year))
    
    lapply(years, function(yr) {
      output[[paste0("daily_", yr)]] <- renderPlotly({
        d <- dat[dat$year == yr, ]
        ts <- d %>% group_by(date) %>% summarise(n = n(), .groups = "drop")
        
        p <- ggplot(ts, aes(date, n)) +
          geom_col(fill = "steelblue") +
          labs(title = paste("Daily -", yr), x = "", y = "Count") +
          theme_minimal()
        ggplotly(p)
      })
      
      div(h4(yr), plotlyOutput(paste0("daily_", yr), height = 300), hr())
    })
  })

  output$monthly_plots <- renderUI({
    dat <- data()
    if (is.null(dat)) return(p("Click Load Data"))
    
    years <- sort(unique(dat$year))
    
    lapply(years, function(yr) {
      output[[paste0("monthly_", yr)]] <- renderPlotly({
        d <- dat[dat$year == yr, ]
        d$month <- floor_date(d$date, "month")
        monthly <- d %>% group_by(month) %>% summarise(n = n(), .groups = "drop")
        
        p <- ggplot(monthly, aes(month, n)) +
          geom_line(color = "steelblue", linewidth = 1) +
          geom_point(color = "darkblue", size = 2) +
          labs(title = paste("Monthly -", yr), x = "", y = "Count") +
          theme_minimal()
        ggplotly(p)
      })
      
      div(h4(yr), plotlyOutput(paste0("monthly_", yr), height = 300), hr())
    })
  })

  output$table <- renderDT({
    dat <- data()
    if (is.null(dat)) return(datatable(data.frame(Message = "No data")))
    datatable(dat, options = list(pageLength = 25))
  })
}

shinyApp(ui, server)