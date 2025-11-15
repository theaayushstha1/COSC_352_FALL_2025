# app.R - Shiny dashboard for Baltimore homicides

library(shiny)
library(tidyverse)
library(DT)
library(ggplot2)

# If data missing, try to run fetch script
if (!file.exists("data/homicides.csv")) {
  if (file.exists("data-fetch.R")) {
    try({ source("data-fetch.R") }, silent = TRUE)
  }
}

homicides <- tryCatch(readr::read_csv("data/homicides.csv"), error = function(e) tibble())

ui <- fluidPage(
  titlePanel("Baltimore City Homicide Dashboard (2021-2025)"),
  sidebarLayout(
    sidebarPanel(
      selectInput("year", "Year:", choices = c("All", sort(unique(homicides$year, na.rm=TRUE))), selected = "All"),
      numericInput("min_age", "Minimum age:", value = NA, min = 0, max = 120),
      textInput("search", "Text search (in notes):", value = ""),
      actionButton("refresh", "Refresh data (re-run fetch)")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Summary", plotOutput("by_month"), verbatimTextOutput("summary_text")),
        tabPanel("Table", DTOutput("table"))
      )
    )
  )
)

server <- function(input, output, session) {
  data <- reactiveVal(homicides)

  observeEvent(input$refresh, {
    # attempt to re-run data fetch
    if (file.exists("data-fetch.R")) {
      withProgress(message = "Refreshing data", value = 0, {
        incProgress(0.2)
        try({ source("data-fetch.R") }, silent = TRUE)
        incProgress(0.8)
      })
      data(tryCatch(readr::read_csv("data/homicides.csv"), error = function(e) tibble()))
    }
  })

  filtered <- reactive({
    df <- data()
    if (is.null(df) || nrow(df) == 0) return(df)
    if (input$year != "All") df <- df %>% filter(year == as.integer(input$year))
    if (!is.na(input$min_age)) df <- df %>% filter(!is.na(age) & age >= input$min_age)
    if (str_trim(input$search) != "") df <- df %>% filter(str_detect(tolower(note), tolower(input$search)))
    df
  })

  output$by_month <- renderPlot({
    df <- filtered()
    if (nrow(df) == 0) return(NULL)
    df2 <- df %>% mutate(month = lubridate::floor_date(date, "month")) %>%
      group_by(month) %>% summarize(n = n()) %>% drop_na()
    if (nrow(df2) == 0) return(NULL)
    ggplot(df2, aes(x = month, y = n)) + geom_col(fill = "firebrick") + theme_minimal() +
      labs(x = "Month", y = "Homicides", title = "Homicides by Month")
  })

  output$summary_text <- renderPrint({
    df <- filtered()
    cat("Rows:", nrow(df), "\n")
    cat("Years present:", paste(sort(unique(df$year, na.rm = TRUE)), collapse = ", "), "\n")
    cat("Ages (min/median/max):", if (nrow(df) > 0) paste(min(df$age, na.rm=TRUE), median(df$age, na.rm=TRUE), max(df$age, na.rm=TRUE)) else "N/A", "\n")
  })

  output$table <- renderDT({
    df <- filtered()
    if (nrow(df) == 0) return(datatable(df))
    datatable(df %>% select(date, year, age, sex, location, note), options = list(pageLength = 25))
  })
}

shinyApp(ui, server)
