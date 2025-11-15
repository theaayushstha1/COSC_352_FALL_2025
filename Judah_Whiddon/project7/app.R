library(shiny)
library(bslib)
library(rvest)
library(dplyr)
library(stringr)
library(tibble)
library(ggplot2)

# ---------------------------------------
# LOAD ALL YEARS
# ---------------------------------------

homicide_urls <- tibble(
  year = c(2021, 2022, 2023, 2024, 2025),
  url = c(
    "http://chamspage.blogspot.com/2021/",
    "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
    "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
    "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
    "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
  )
)

# Load a single year's table
load_year <- function(year, url) {
  message("Loading year: ", year)

  page <- tryCatch(read_html(url), error = function(e) NULL)
  if (is.null(page)) return(NULL)

  tables <- html_table(page, fill = TRUE)
  df <- tables[[1]]
  df$Year <- year
  df
}

# Download all years
homicides_raw <- bind_rows(
  lapply(1:nrow(homicide_urls), function(i) {
    load_year(homicide_urls$year[i], homicide_urls$url[i])
  })
)

# Clean column names
names(homicides_raw) <- names(homicides_raw) |>
  str_replace_all("\\s+", "_") |>
  str_replace_all("\\.", "") |>
  str_trim()

# Rename first 9 columns if needed
if (ncol(homicides_raw) >= 9) {
  colnames(homicides_raw)[1:9] <- c(
    "No", "DateDied", "Name", "Age", "AddressFound",
    "Notes", "VictimHistory", "SurveillanceCamera", "CaseClosed"
  )
}

# ---------------------------------------
# UI
# ---------------------------------------

ui <- page_sidebar(
  theme = bs_theme(
    version    = 5,
    bootswatch = "darkly",
    base_font  = font_google("Inter")
  ),

  title = "Baltimore Homicides Dashboard (2021–2025)",

  sidebar = sidebar(
    h4("Filters"),
    selectInput(
      "year",
      "Year",
      choices  = sort(unique(homicides_raw$Year)),
      selected = max(homicides_raw$Year)
    )
  ),

  
  # Charts + table row
  layout_columns(
    col_widths = c(6, 6),

    card(
      full_screen = TRUE,
      card_header("Total Homicides Per Year"),
      plotOutput("yearPlot", height = "320px")
    ),

    card(
      full_screen = TRUE,
      card_header("Cases for Selected Year"),
      dataTableOutput("table")
    )
  )
)

# ---------------------------------------
# SERVER
# ---------------------------------------

server <- function(input, output, session) {

  # Data for selected year
  year_data <- reactive({
    homicides_raw %>% filter(Year == input$year)
  })

  # Summary cards
  output$total_cases <- renderText({
    nrow(year_data())
  })

  output$avg_age <- renderText({
    ages <- suppressWarnings(as.numeric(year_data()$Age))
    if (all(is.na(ages))) return("N/A")
    round(mean(ages, na.rm = TRUE), 1)
  })

  output$closed_pct <- renderText({
    dat <- year_data()
    if (nrow(dat) == 0) return("0%")
    closed <- !is.na(dat$CaseClosed) & dat$CaseClosed != ""
    pct <- round(100 * sum(closed) / nrow(dat), 1)
    paste0(pct, "%")
  })

  # Plot
  output$yearPlot <- renderPlot({
    homicides_raw %>%
      count(Year) %>%
      ggplot(aes(x = factor(Year), y = n, fill = factor(Year))) +
      geom_col() +
      theme_minimal(base_family = "Inter") +
      labs(x = "Year", y = "Total Homicides", fill = "Year")
  })

  # Table
  output$table <- renderDataTable({
    year_data()
  })
}

# ---------------------------------------
# RUN APP
# ---------------------------------------

shinyApp(ui, server)
