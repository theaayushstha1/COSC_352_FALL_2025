library(shiny)
library(dplyr)
library(rvest)
library(janitor)
library(lubridate)
library(ggplot2)
library(DT)

# -------------------------------
# URLs for homicide datasets
# -------------------------------
urls <- c(
  "2021" = "https://chamspage.blogspot.com/2021/01/2021-baltimore-city-homicides-list.html",
  "2022" = "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
  "2023" = "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
  "2024" = "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
  "2025" = "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
)

# -------------------------------
# Load and clean a single year
# -------------------------------
load_year <- function(year_chr, url) {
  message("Loading year ", year_chr, " from: ", url)
  page <- read_html(url)
  tables <- html_table(page, fill = TRUE)

  if (length(tables) == 0) {
    warning("No tables found for year ", year_chr)
    return(NULL)
  }

  df <- tables[[1]] |> clean_names()

  # Try to identify a date column (site uses variations like "date_died", etc.)
  date_col <- names(df)[grepl("date", names(df), ignore.case = TRUE)]
  if (length(date_col) > 0) {
    date_chr <- as.character(df[[date_col[1]]])
  } else {
    date_chr <- NA_character_
  }

  # Clean date using multiple possible formats
  date_parsed <- suppressWarnings(
    parse_date_time(
      date_chr,
      orders = c("mdy", "m/d/y", "m/d/Y", "Y-m-d")
    )
  )

  df$date <- as.Date(date_parsed)

  # Clean age if present
  if ("age" %in% names(df)) {
    df$age <- suppressWarnings(as.numeric(df$age))
  } else {
    df$age <- NA_real_
  }

  df$year <- as.integer(year_chr)

  # Ensure address-like columns exist
  if (!"address" %in% names(df)) df$address <- NA_character_
  if (!"block_found" %in% names(df)) df$block_found <- NA_character_
  if (!"notes" %in% names(df)) df$notes <- NA_character_

  df
}

# -------------------------------
# Load ALL years together
# -------------------------------
homicides_list <- lapply(names(urls), function(y) {
  load_year(y, urls[[y]])
})

homicides <- bind_rows(homicides_list)

# Remove rows that are completely empty (base R to avoid dplyr scoping issues)
if (!is.null(homicides) && nrow(homicides) > 0) {
  homicides <- homicides[rowSums(is.na(homicides)) < ncol(homicides), , drop = FALSE]
}

# Add month column for time series plots
homicides <- homicides |>
  mutate(
    month = floor_date(date, "month")
  )

# Fallbacks in case of weird data (avoid crashes in UI)
min_date <- suppressWarnings(min(homicides$date, na.rm = TRUE))
max_date <- suppressWarnings(max(homicides$date, na.rm = TRUE))
if (!is.finite(min_date)) min_date <- as.Date("2021-01-01")
if (!is.finite(max_date)) max_date <- Sys.Date()

if (all(is.na(homicides$age))) {
  min_age <- 0
  max_age <- 100
} else {
  min_age <- min(homicides$age, na.rm = TRUE)
  max_age <- max(homicides$age, na.rm = TRUE)
}

# -------------------------------
# UI
# -------------------------------
ui <- fluidPage(
  titlePanel("Baltimore City Homicides Dashboard (2021–2025)"),

  sidebarLayout(
    sidebarPanel(
      checkboxGroupInput(
        "years",
        "Select year(s):",
        choices = sort(unique(homicides$year)),
        selected = sort(unique(homicides$year))
      ),

      dateRangeInput(
        "daterange",
        "Date range:",
        start = min_date,
        end   = max_date
      ),

      sliderInput(
        "ageRange",
        "Age range:",
        min = min_age,
        max = max_age,
        value = c(min_age, max_age)
      ),

      textInput(
        "search",
        "Search address / block / notes:",
        ""
      )
    ),

    mainPanel(
      tabsetPanel(
        tabPanel(
          "Overview",
          h3(textOutput("summary_text")),
          br(),
          h4("Homicides by Year"),
          plotOutput("plot_year", height = "300px"),
          br(),
          h4("Homicides by Month (across selected years)"),
          plotOutput("plot_month", height = "300px")
        ),
        tabPanel(
          "Data Table",
          DTOutput("table")
        )
      )
    )
  )
)

# -------------------------------
# SERVER
# -------------------------------
server <- function(input, output, session) {

  filtered <- reactive({
    df <- homicides

    # Year filter
    if (!is.null(input$years) && length(input$years) > 0) {
      df <- df |> filter(year %in% as.integer(input$years))
    }

    # Date range filter
    if (!is.null(input$daterange) && all(!is.na(input$daterange))) {
      df <- df |>
        filter(is.na(date) | (date >= input$daterange[1] & date <= input$daterange[2]))
    }

    # Age range filter
    if (!is.null(input$ageRange)) {
      df <- df |>
        filter(is.na(age) | (age >= input$ageRange[1] & age <= input$ageRange[2]))
    }

    # Text search across address, block_found, notes
    txt <- trimws(input$search)
    if (nzchar(txt)) {
      txt_lower <- tolower(txt)
      search_blob <- paste(
        tolower(ifelse(is.na(df$address), "", df$address)),
        tolower(ifelse(is.na(df$block_found), "", df$block_found)),
        tolower(ifelse(is.na(df$notes), "", df$notes)),
        sep = " "
      )
      keep <- grepl(txt_lower, search_blob, fixed = TRUE)
      df <- df[keep, , drop = FALSE]
    }

    df
  })

  # Summary text
  output$summary_text <- renderText({
    df <- filtered()
    total <- nrow(df)
    yrs <- sort(unique(df$year))
    if (length(yrs) == 0) {
      "No homicides match the selected filters."
    } else {
      paste0(
        "Total homicides in selected filters: ",
        total,
        " | Years: ",
        paste(yrs, collapse = ", ")
      )
    }
  })

  # Homicides by year
  output$plot_year <- renderPlot({
    df <- filtered()
    if (nrow(df) == 0) return(NULL)

    df |>
      count(year) |>
      ggplot(aes(x = factor(year), y = n)) +
      geom_col() +
      labs(x = "Year", y = "Number of homicides") +
      theme_minimal()
  })

  # Homicides by month (time series)
  output$plot_month <- renderPlot({
    df <- filtered() |> filter(!is.na(month))
    if (nrow(df) == 0) return(NULL)

    df |>
      count(month) |>
      ggplot(aes(x = month, y = n)) +
      geom_line() +
      geom_point() +
      labs(x = "Month", y = "Number of homicides") +
      theme_minimal()
  })

  # Data table
  output$table <- renderDT({
    df <- filtered()
    datatable(
      df,
      options = list(pageLength = 25),
      filter = "top"
    )
  })
}

shinyApp(ui, server)
