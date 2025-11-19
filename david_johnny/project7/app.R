# app.R
# Baltimore Homicide Lists - Simple Table Parser with Separate Year Plots

library(shiny)
library(dplyr)
library(ggplot2)
library(rvest)
library(lubridate)
library(DT)
library(plotly)

# ----------- SHINY APP -----------

ui <- fluidPage(
  titlePanel("Baltimore City Homicides - By Year"),
  
  sidebarLayout(
    sidebarPanel(
      actionButton("reload", "Load Data", class = "btn-primary"),
      hr(),
      verbatimTextOutput("status"),
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
    
    tryCatch({
      urls <- c(
        "https://chamspage.blogspot.com/2021/",
        "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
        "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
        "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
        "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
      )
      
      all_data <- list()
      debug_info <- list()
      
      for (url in urls) {
        Sys.sleep(1)
        
        page <- read_html(url)
        tables <- html_table(page, fill = TRUE)
        
        debug_info[[url]] <- list(
          url = url,
          num_tables = length(tables),
          table_sizes = if(length(tables) > 0) sapply(tables, nrow) else 0
        )
        
        if (length(tables) > 0) {
          tbl <- tables[[which.max(sapply(tables, nrow))]]
          
          # Skip if table is too small (likely not the data table)
          if (nrow(tbl) < 5) {
            debug_info[[url]]$skipped <- TRUE
            next
          }
          
          debug_info[[url]]$columns <- names(tbl)
          debug_info[[url]]$first_col_sample <- head(tbl[[1]], 3)
          
          tbl$source_url <- url
          all_data[[url]] <- tbl
        }
      }
      
      if (length(all_data) == 0) {
        removeModal()
        msg <- "No tables found.\n\nDebug info:\n"
        for (info in debug_info) {
          msg <- paste0(msg, "\n", info$url, ": ", info$num_tables, " tables found")
        }
        showModal(modalDialog(msg, footer = modalButton("OK")))
        return()
      }
      
      raw <- bind_rows(all_data)
      
      # The first column is usually row numbers, so try second column for dates
      date_col <- if(ncol(raw) >= 2) raw[[2]] else raw[[1]]
      
      # Parse dates - try multiple formats
      raw$date <- parse_date_time(date_col, 
                                  orders = c("mdy", "m/d/y", "m-d-y", "dmy", "d/m/y"), 
                                  quiet = TRUE)
      raw$year <- year(raw$date)
      
      # Filter valid dates
      clean <- raw[!is.na(raw$date), ]
      
      if (nrow(clean) == 0) {
        removeModal()
        date_col_name <- if(ncol(raw) >= 2) names(raw)[2] else names(raw)[1]
        date_col_vals <- if(ncol(raw) >= 2) raw[[2]] else raw[[1]]
        msg <- paste0("Tables found but no dates parsed.\n\n",
                     "Total rows: ", nrow(raw), "\n",
                     "Date column name: ", date_col_name, "\n",
                     "Sample values: ", paste(head(date_col_vals, 3), collapse = ", "))
        showModal(modalDialog(msg, footer = modalButton("OK")))
        return()
      }
      
      data(clean)
      removeModal()
      
      showModal(modalDialog(
        paste("Loaded", nrow(clean), "records from", length(unique(clean$year)), "years"), 
        footer = modalButton("OK")
      ))
      
    }, error = function(e) {
      removeModal()
      showModal(modalDialog(paste("Error:", e$message), footer = modalButton("OK")))
    })
  })

  output$status <- renderPrint({
    dat <- data()
    if (is.null(dat)) {
      cat("No data loaded\n")
    } else {
      cat("Records:", nrow(dat), "\n")
      cat("Years:", paste(sort(unique(dat$year)), collapse = ", "), "\n")
    }
  })

  output$daily_plots <- renderUI({
    dat <- data()
    if (is.null(dat)) return(div(p("Click Load Data to begin")))
    
    years <- sort(unique(dat$year))
    
    plots <- lapply(years, function(yr) {
      plotname <- paste0("daily_", yr)
      
      output[[plotname]] <- renderPlotly({
        d <- dat[dat$year == yr, ]
        ts <- d %>% 
          group_by(date) %>% 
          summarise(n = n(), .groups = "drop")
        
        p <- ggplot(ts, aes(date, n)) +
          geom_col(fill = "steelblue") +
          labs(title = paste("Daily Homicides -", yr), x = "Date", y = "Count") +
          theme_minimal()
        
        ggplotly(p)
      })
      
      div(
        h4(paste("Year:", yr)),
        plotlyOutput(plotname, height = 300),
        hr()
      )
    })
    
    do.call(tagList, plots)
  })

  output$monthly_plots <- renderUI({
    dat <- data()
    if (is.null(dat)) return(div(p("Click Load Data to begin")))
    
    years <- sort(unique(dat$year))
    
    plots <- lapply(years, function(yr) {
      plotname <- paste0("monthly_", yr)
      
      output[[plotname]] <- renderPlotly({
        d <- dat[dat$year == yr, ]
        d$month <- floor_date(d$date, "month")
        monthly <- d %>% 
          group_by(month) %>% 
          summarise(n = n(), .groups = "drop")
        
        p <- ggplot(monthly, aes(month, n)) +
          geom_line(color = "steelblue", linewidth = 1) +
          geom_point(color = "darkblue", size = 2) +
          labs(title = paste("Monthly Homicides -", yr), x = "Month", y = "Count") +
          theme_minimal()
        
        ggplotly(p)
      })
      
      div(
        h4(paste("Year:", yr)),
        plotlyOutput(plotname, height = 300),
        hr()
      )
    })
    
    do.call(tagList, plots)
  })

  output$table <- renderDT({
    dat <- data()
    if (is.null(dat)) {
      return(datatable(data.frame(Message = "No data loaded. Click Load Data button.")))
    }
    datatable(dat, options = list(pageLength = 25, scrollX = TRUE))
  })
}

shinyApp(ui, server)