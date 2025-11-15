# app.R
# Baltimore Homicide Lists (Chamspage) Dashboard - Tables Only (No Geocoding)

library(shiny)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(ggplot2)
library(rvest)
library(lubridate)
library(DT)
library(plotly)

# ----------- SCRAPER -----------

scrape_chamspage_table <- function(url) {
  # Add small delay to be polite to server
  Sys.sleep(1)
  
  page <- tryCatch(read_html(url), error = function(e) {
    message(paste("Error fetching", url, ":", e$message))
    return(NULL)
  })
  if (is.null(page)) return(tibble(source_url = url, error = "Could not fetch page"))

  tables <- page %>% html_nodes("table")
  if (length(tables) == 0)
    return(tibble(source_url = url, error = "No table found"))

  # Try all tables and pick the biggest
  parsed <- tables %>%
    map(~ tryCatch(html_table(.x, fill = TRUE) %>% as_tibble(), error = function(e) NULL)) %>%
    compact()

  if (length(parsed) == 0)
    return(tibble(source_url = url, error = "Table could not be parsed"))

  best <- parsed[[which.max(map_int(parsed, nrow))]]
  best$source_url <- url
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

  raw <- map(urls, scrape_chamspage_table)
  names(raw) <- urls
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
    date_raw = if (length(date_col)>0) tbl[[date_col[1]]] else NA_character_,
    name     = if (length(name_col)>0) tbl[[name_col[1]]] else NA_character_,
    age      = if (length(age_col)>0) tbl[[age_col[1]]] else NA_character_,
    address  = if (length(address_col)>0) tbl[[address_col[1]]] else NA_character_,
    notes    = if (length(notes_col)>0) tbl[[notes_col[1]]] else NA_character_,
    source_url = tbl$source_url[1]
  )
}

# ----------- NO INITIAL LOAD - START WITH EMPTY DATASET -----------

create_empty_dataset <- function() {
  tibble(
    date_raw = character(0),
    name = character(0),
    age = character(0),
    address = character(0),
    notes = character(0),
    source_url = character(0),
    date = structure(numeric(0), class = "Date"),
    year = numeric(0),
    id = numeric(0)
  )
}

# ----------- SHINY APP -----------

ui <- fluidPage(
  titlePanel("Baltimore City Homicide Lists (Chamspage) - 2021-2025"),
  
  div(
    style = "background-color: #fff3cd; padding: 15px; margin-bottom: 20px; border-radius: 5px;",
    strong("Note:"), " Click 'Load Data' to scrape and load homicide records from Chamspage blog."
  ),

  sidebarLayout(
    sidebarPanel(
      actionButton("reload", "Load Data", class = "btn-primary", style = "margin-bottom: 15px;"),
      hr(),
      selectInput("year", "Year", choices = c("All"), selected = "All"),
      textInput("name_filter", "Name contains", value = ""),
      checkboxInput("only_camera", "Only cases mentioning cameras", FALSE),
      hr(),
      helpText("Data scraped from Chamspage blog."),
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

  ds <- reactiveVal(create_empty_dataset())
  
  # Track loading state
  loading <- reactiveVal(FALSE)

  # Update year choices when data changes
  observe({
    d <- ds()
    if (nrow(d) > 0) {
      years <- sort(unique(d$year[!is.na(d$year)]))
      updateSelectInput(session, "year", 
                       choices = c("All", years))
    }
  })

  # Load/Re-scrape data
  observeEvent(input$reload, {
    if (loading()) return()
    
    loading(TRUE)
    showModal(modalDialog(
      "Scraping pages... This may take 10-20 seconds.", 
      footer = NULL,
      easyClose = FALSE
    ))
    
    # Use future/promises or just do it synchronously with better error handling
    tryCatch({
      new_raw <- load_all_years()
      new_norm <- new_raw %>%
        map_df(normalize_chams_table) %>%
        filter(!is.na(date_raw), date_raw != "") %>%
        mutate(
          date = parse_date_time(date_raw, orders=c("mdy","m/d/y","m/d/Y"), truncated=3),
          year = year(date),
          age = as.numeric(str_extract(as.character(age), "\\d{1,3}")),
          address = str_squish(as.character(address)),
          notes = str_squish(as.character(notes)),
          id = row_number()
        )
      
      if (nrow(new_norm) > 0) {
        ds(new_norm)
        removeModal()
        showModal(modalDialog(
          paste("Success! Loaded", nrow(new_norm), "records."), 
          footer = modalButton("OK")
        ))
      } else {
        removeModal()
        showModal(modalDialog(
          "No data found. The scraper may have encountered issues.", 
          footer = modalButton("OK")
        ))
      }
    }, error = function(e) {
      removeModal()
      showModal(modalDialog(
        paste("Error loading data:", e$message), 
        footer = modalButton("OK")
      ))
    })
    
    loading(FALSE)
  })

  filtered <- reactive({
    out <- ds()

    if (nrow(out) == 0) return(out)

    if (input$year != "All")
      out <- out %>% filter(year == as.integer(input$year))

    if (input$name_filter != "")
      out <- out %>% filter(str_detect(tolower(coalesce(name,"")), tolower(input$name_filter)))

    if (input$only_camera)
      out <- out %>% filter(str_detect(tolower(coalesce(notes,"")), "camera"))

    out
  })

  output$table <- renderDT({
    if (nrow(filtered()) == 0) {
      return(datatable(
        tibble(Message = "No data loaded. Click 'Load Data' button to scrape and load records."),
        options = list(dom = 't')
      ))
    }
    
    datatable(
      filtered() %>% select(id, date, year, name, age, address, notes, source_url),
      options = list(pageLength = 25, scrollX = TRUE),
      filter = 'top'
    )
  })

  output$timeline_plot <- renderPlotly({
    dat <- filtered() %>% filter(!is.na(date))
    if (nrow(dat)==0) {
      p <- plot_ly() %>%
        layout(
          title = list(text = "No data available"),
          xaxis = list(visible = FALSE),
          yaxis = list(visible = FALSE),
          annotations = list(
            text = "Click 'Load Data' to begin",
            showarrow = FALSE,
            font = list(size = 16)
          )
        )
      return(p)
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
      p <- plot_ly() %>%
        layout(
          title = list(text = "No data available"),
          xaxis = list(visible = FALSE),
          yaxis = list(visible = FALSE),
          annotations = list(
            text = "Click 'Load Data' to begin",
            showarrow = FALSE,
            font = list(size = 16)
          )
        )
      return(p)
    }

    monthly <- dat %>%
      mutate(month = floor_date(date, "month")) %>%
      count(month)

    p <- ggplot(monthly, aes(month, n)) +
      geom_line(color = "steelblue", linewidth = 1) +
      geom_point(color = "darkblue", size = 2) +
      labs(title="Monthly Trend", x="Month", y="Homicides") +
      theme_minimal()

    ggplotly(p)
  })

  output$diag <- renderPrint({
    d <- ds()
    cat("Records loaded:", nrow(d), "\n")
    
    if (nrow(d) == 0) {
      cat("\nNo data loaded yet. Click 'Load Data' button to scrape records.\n")
      return()
    }
    
    cat("Records with valid dates:", sum(!is.na(d$date)), "\n")
    cat("Years present:", paste(sort(unique(d$year[!is.na(d$year)])), collapse=", "), "\n")
    
    if (any(!is.na(d$date))) {
      cat("\nDate range:", as.character(min(d$date, na.rm=TRUE)), "to", as.character(max(d$date, na.rm=TRUE)), "\n")
    }
    
    cat("\nSource URLs:\n")
    print(unique(d$source_url))
  })
}

shinyApp(ui, server)