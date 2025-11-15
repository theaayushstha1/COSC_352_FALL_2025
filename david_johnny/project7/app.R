# app.R
# Baltimore Homicide Lists (Chamspage) Dashboard - Tables Only (No Geocoding)

library(shiny)
library(tidyverse)
library(rvest)
library(lubridate)
library(DT)
library(plotly)

# ----------- SCRAPER -----------

scrape_chamspage_table <- function(url) {
  # Add small delay to be polite to server
  Sys.sleep(0.5)
  
  message("Fetching: ", url)
  
  page <- tryCatch({
    read_html(url)
  }, error = function(e) {
    message("Error fetching ", url, ": ", e$message)
    return(NULL)
  })
  
  if (is.null(page)) return(tibble(source_url = url, error = "Could not fetch page"))

  tables <- page %>% html_nodes("table")
  if (length(tables) == 0) {
    message("No tables found on ", url)
    return(tibble(source_url = url, error = "No table found"))
  }

  # Try all tables and pick the biggest
  parsed <- tables %>%
    map(~ tryCatch(html_table(.x, fill = TRUE) %>% as_tibble(), error = function(e) NULL)) %>%
    compact()

  if (length(parsed) == 0) {
    message("Could not parse tables from ", url)
    return(tibble(source_url = url, error = "Table could not be parsed"))
  }

  best <- parsed[[which.max(map_int(parsed, nrow))]]
  best$source_url <- url
  message("Successfully scraped ", nrow(best), " rows from ", url)
  best
}

load_all_years <- function() {
  urls <- c(
    "https://chamspage.blogspot.com/2021/",
    "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
    "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
    "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
    "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
  )

  message("Starting scrape of ", length(urls), " pages...")
  raw <- map(urls, scrape_chamspage_table)
  names(raw) <- urls
  message("Scraping complete!")
  raw
}

# ----------- NORMALIZATION -----------

normalize_chams_table <- function(tbl) {
  # Remove obviously broken tables
  if (!is_tibble(tbl)) return(NULL)
  if (nrow(tbl) == 0) return(NULL)
  if ("error" %in% names(tbl)) return(NULL)

  # Clean column names
  names(tbl) <- names(tbl) %>%
    str_replace_all("\\n", " ") %>%
    str_squish() %>%
    tolower()

  # Identify expected fields
  date_col   <- names(tbl)[str_detect(names(tbl), "date")]
  name_col   <- names(tbl)[str_detect(names(tbl), "name")]
  age_col    <- names(tbl)[str_detect(names(tbl), "\\bage\\b")]
  address_col <- names(tbl)[str_detect(names(tbl), "address|block")]
  notes_col  <- names(tbl)[str_detect(names(tbl), "notes|found")]

  tibble(
    date_raw = if (length(date_col)>0) tbl[[date_col[1]]] else NA,
    name     = if (length(name_col)>0) tbl[[name_col[1]]] else NA,
    age      = if (length(age_col)>0) tbl[[age_col[1]]] else NA,
    address  = if (length(address_col)>0) tbl[[address_col[1]]] else NA,
    notes    = if (length(notes_col)>0) tbl[[notes_col[1]]] else NA,
    source_url = tbl$source_url[1]
  )
}

# ----------- INITIAL LOAD WITH ERROR HANDLING -----------

message("=== App starting up ===")

# Try to load data, but don't crash if it fails
dataset <- tryCatch({
  message("Attempting initial data load...")
  raw_tables <- load_all_years()
  
  result <- raw_tables %>%
    map_df(normalize_chams_table) %>%
    mutate(
      date = parse_date_time(date_raw, orders = c("mdy", "m/d/y", "m/d/Y"), truncated = 3),
      year = year(date),
      age = as.numeric(str_extract(as.character(age), "\\d{1,3}")),
      address = str_squish(as.character(address)),
      notes = str_squish(as.character(notes)),
      id = row_number()
    )
  
  message("Successfully loaded ", nrow(result), " records")
  result
}, error = function(e) {
  message("ERROR during initial load: ", e$message)
  message("Creating empty dataset - use 'Re-scrape' button to load data")
  
  # Return empty but valid structure
  tibble(
    date_raw = character(),
    name = character(),
    age = numeric(),
    address = character(),
    notes = character(),
    source_url = character(),
    date = as.POSIXct(character()),
    year = numeric(),
    id = numeric()
  )
})

message("=== App initialization complete ===")

# ----------- SHINY APP -----------

ui <- fluidPage(
  titlePanel("Baltimore City Homicide Lists (Chamspage) - 2021-2025 (Tables Only)"),

  sidebarLayout(
    sidebarPanel(
      selectInput("year", "Year", 
                  choices = c("All", sort(unique(dataset$year[!is.na(dataset$year)]))), 
                  selected = "All"),
      textInput("name_filter", "Name contains", value = ""),
      checkboxInput("only_camera", "Only cases mentioning cameras", FALSE),
      actionButton("reload", "Re-scrape pages", class = "btn-primary"),
      hr(),
      helpText("Data scraped from Chamspage blog. Click 'Re-scrape' to load/update data."),
      hr(),
      uiOutput("status_text"),
      width = 3
    ),

    mainPanel(
      tabsetPanel(
        tabPanel("Timeline", plotlyOutput("timeline_plot", height = 400)),
        tabPanel("Monthly Trend", plotlyOutput("monthly_plot", height = 400)),
        tabPanel("Table", DTOutput("table")),
        tabPanel("Diagnostics", verbatimTextOutput("diag"))
      )
    )
  )
)

server <- function(input, output, session) {

  ds <- reactiveVal(dataset)
  status_msg <- reactiveVal(
    if(nrow(dataset) > 0) {
      paste("Loaded", nrow(dataset), "records")
    } else {
      "No data loaded - click 'Re-scrape' to load data"
    }
  )

  output$status_text <- renderUI({
    if(nrow(ds()) > 0) {
      tags$div(
        style = "color: green; font-weight: bold;",
        icon("check-circle"),
        status_msg()
      )
    } else {
      tags$div(
        style = "color: orange; font-weight: bold;",
        icon("exclamation-triangle"),
        status_msg()
      )
    }
  })

  # Re-scrape if needed
  observeEvent(input$reload, {
    showModal(modalDialog(
      "Re-scraping pages... This may take 30-60 seconds.",
      footer = NULL,
      easyClose = FALSE
    ))
    
    status_msg("Scraping in progress...")
    
    tryCatch({
      new_raw <- load_all_years()
      new_norm <- new_raw %>%
        map_df(normalize_chams_table) %>%
        mutate(
          date = parse_date_time(date_raw, orders=c("mdy","m/d/y","m/d/Y"), truncated=3),
          year = year(date),
          age = as.numeric(str_extract(as.character(age), "\\d{1,3}")),
          address = str_squish(as.character(address)),
          notes = str_squish(as.character(notes)),
          id = row_number()
        )
      
      ds(new_norm)
      
      # Update year choices
      updateSelectInput(session, "year", 
                       choices = c("All", sort(unique(new_norm$year[!is.na(new_norm$year)]))))
      
      status_msg(paste("Successfully loaded", nrow(new_norm), "records"))
      removeModal()
      showModal(modalDialog(
        paste("Data updated successfully! Loaded", nrow(new_norm), "records."),
        footer = modalButton("OK")
      ))
    }, error = function(e) {
      status_msg(paste("Error:", e$message))
      removeModal()
      showModal(modalDialog(
        paste("Error loading data:", e$message, 
              "\n\nPlease check your internet connection and try again."),
        footer = modalButton("OK")
      ))
    })
  })

  filtered <- reactive({
    out <- ds()
    
    if(nrow(out) == 0) return(out)

    if (input$year != "All")
      out <- out %>% filter(year == as.integer(input$year))

    if (input$name_filter != "")
      out <- out %>% filter(str_detect(tolower(coalesce(name,"")), tolower(input$name_filter)))

    if (input$only_camera)
      out <- out %>% filter(str_detect(tolower(coalesce(notes,"")), "camera"))

    out
  })

  output$table <- renderDT({
    dat <- filtered()
    if(nrow(dat) == 0) {
      return(datatable(tibble(Message = "No data available. Click 'Re-scrape pages' to load data.")))
    }
    
    datatable(
      dat %>% select(id, date, year, name, age, address, notes, source_url),
      options = list(pageLength = 25, scrollX = TRUE),
      filter = 'top'
    )
  })

  output$timeline_plot <- renderPlotly({
    dat <- filtered() %>% filter(!is.na(date))
    if (nrow(dat)==0) {
      return(plotly_empty() %>% 
               layout(title = "No data available - click 'Re-scrape pages' to load data"))
    }

    ts <- dat %>% count(date)

    p <- ggplot(ts, aes(date, n)) +
      geom_col(fill = "steelblue") +
      labs(title="Daily Count", x="Date", y="Homicides") +
      theme_minimal()

    ggplotly(p)
  })

  output$monthly_plot <- renderPlotly({
    dat <- filtered() %>% filter(!is.na(date))
    if (nrow(dat)==0) {
      return(plotly_empty() %>% 
               layout(title = "No data available - click 'Re-scrape pages' to load data"))
    }

    monthly <- dat %>%
      mutate(month = floor_date(date, "month")) %>%
      count(month)

    p <- ggplot(monthly, aes(month, n)) +
      geom_line(color = "steelblue", size = 1) + 
      geom_point(color = "darkblue", size = 2) +
      labs(title="Monthly Trend", x="Month", y="Homicides") +
      theme_minimal()

    ggplotly(p)
  })

  output$diag <- renderPrint({
    d <- ds()
    cat("=== Baltimore Homicide Dashboard Diagnostics ===\n\n")
    cat("Records loaded:", nrow(d), "\n")
    
    if(nrow(d) > 0) {
      cat("Records with valid dates:", sum(!is.na(d$date)), "\n")
      cat("Years present:", paste(sort(unique(d$year)), collapse=", "), "\n")
      
      if(sum(!is.na(d$date)) > 0) {
        cat("\nDate range:", as.character(min(d$date, na.rm=TRUE)), 
            "to", as.character(max(d$date, na.rm=TRUE)), "\n")
      }
      
      cat("\nSource URLs:\n")
      print(unique(d$source_url))
      
      cat("\nSample records:\n")
      print(head(d %>% select(date, name, age, address), 5))
    } else {
      cat("\nNo data loaded. Click 'Re-scrape pages' button to load data.\n")
      cat("\nThis may happen if:\n")
      cat("  - Initial scrape timed out during startup\n")
      cat("  - Network connection was unavailable\n")
      cat("  - Chamspage blog was unreachable\n")
    }
  })
}

shinyApp(ui, server)