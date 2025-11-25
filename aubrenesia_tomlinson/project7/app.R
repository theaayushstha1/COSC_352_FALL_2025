
library(rvest)
library(dplyr)
library(stringr)
library(purrr)
library(lubridate)
library(readr)
library(ggplot2)
library(DT)
library(shiny)


urls <- c(
  "http://chamspage.blogspot.com/2021/",
  "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
  "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
  "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
  "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
)

scrape_year <- function(url) {
  page <- read_html(url)

  rows <- page %>% html_nodes("tr")

  data <- rows %>%
    map(~ .x %>% html_nodes("td") %>% html_text(trim = TRUE)) %>%
    keep(~ length(.x) >= 9) %>%
    map_df(~ tibble(
      number          = .x[1],
      date_died       = .x[2],
      name            = .x[3],
      age             = .x[4],
      address_block   = .x[5],
      notes           = .x[6],
      violent_history = .x[7],
      surveillance    = .x[8],
      case_closed     = .x[9]
    ))

  return(data)
}

all_data <- bind_rows(lapply(urls, scrape_year))


extract_year_go <- function(date_str) {
  parsed <- suppressWarnings(mdy(date_str))
  if (is.na(parsed)) return(0)
  year(parsed)
}

all_data <- all_data %>%
  mutate(
    year = extract_year_go(date_died),
    age_num = suppressWarnings(as.numeric(age))
  )

average_age_in_year <- function(df, yr) {
  df %>%
    filter(year == yr, !is.na(age_num), age_num > 0) %>%
    summarise(avg_age = mean(age_num)) %>%
    pull(avg_age)
}

count_surveillance_cases <- function(df, yr) {
  df %>%
    filter(year == yr & grepl("camera", tolower(surveillance))) %>%
    nrow()
}

avg_age_2025 <- average_age_in_year(all_data, 2025)
cam_count_2025 <- count_surveillance_cases(all_data, 2025)

cat("Average age in 2025:", avg_age_2025, "\n")
cat("Surveillance camera cases in 2025:", cam_count_2025, "\n")


ui <- fluidPage(
  titlePanel("Baltimore Homicides Dashboard (2021–2025)"),

  sidebarLayout(
    sidebarPanel(
      sliderInput("year", "Year Range:",
                  min = 2021, max = 2025, value = c(2021, 2025), sep = "")
    ),

    mainPanel(
      tabsetPanel(
        tabPanel("Trends", plotOutput("trend")),
        tabPanel("Age Distribution", plotOutput("age_plot")),
        tabPanel("Raw Data Table", DTOutput("table")),
        tabPanel("Computed Stats",
                 verbatimTextOutput("stats_text"))
      )
    )
  )
)

server <- function(input, output) {

  filtered <- reactive({
    all_data %>% filter(year >= input$year[1], year <= input$year[2])
  })

  output$trend <- renderPlot({
    filtered() %>%
      mutate(month = floor_date(mdy(date_died), "month")) %>%
      count(month) %>%
      ggplot(aes(month, n)) +
      geom_line(color="red", linewidth=1.2) +
      labs(title="Homicides Per Month",
           x="Month", y="Count")
  })

  output$age_plot <- renderPlot({
    filtered() %>%
      filter(!is.na(age_num)) %>%
      ggplot(aes(age_num)) +
      geom_histogram(binwidth=5, fill="steelblue") +
      labs(title="Victim Age Distribution", x="Age", y="Count")
  })

  output$table <- renderDT({
    datatable(filtered(), options = list(pageLength = 20))
  })

  output$stats_text <- renderPrint({
    list(
      average_age_2025 = avg_age_2025,
      surveillance_camera_cases_2025 = cam_count_2025
    )
  })
}

shinyApp(ui, server)
