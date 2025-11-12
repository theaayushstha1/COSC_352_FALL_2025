library(shiny)
library(shinydashboard)
library(rvest)
library(stringr)
library(dplyr)
library(ggplot2)
library(DT)

ui <- dashboardPage(
  dashboardHeader(title = "Baltimore Homicide Dashboard"),
  dashboardSidebar(
    selectInput("years", "Select Years", choices = 2021:2025, multiple = TRUE, selected = 2021:2025)
  ),
  dashboardBody(
    tabBox(
      title = "Visualizations",
      tabPanel("Yearly Totals", plotOutput("yearlyPlot")),
      tabPanel("Monthly Breakdown", plotOutput("monthlyPlot")),
      tabPanel("Closure Rates", 
               valueBoxOutput("totalBox"),
               valueBoxOutput("closureRateBox"),
               valueBoxOutput("cameraClosureBox")
      )
    ),
    dataTableOutput("dataTable")
  )
)

server <- function(input, output) {
  data <- reactive({
    years <- as.character(input$years)
    all_entries <- data.frame(
      year = character(), number = character(), date = character(), 
      month = integer(), has_camera = logical(), is_closed = logical(), 
      description = character(), stringsAsFactors = FALSE
    )
    for (year in years) {
      url <- if (year %in% c("2024", "2025")) {
        paste0("https://chamspage.blogspot.com/", year, "/01/", year, "-baltimore-city-homicide-list.html")
      } else {
        paste0("https://chamspage.blogspot.com/", year, "/01/", year, "-baltimore-city-homicides-list.html")
      }
      tryCatch({
        page <- read_html(url)
        text <- html_text(page)
        clean_text <- str_replace_all(text, "<[^>]+>", "")
        clean_text <- str_replace_all(clean_text, "\\r", "")
        clean_text <- str_replace_all(clean_text, "\\s+", " ")
        footer_start <- str_locate(clean_text, "Post a Comment")[1,1]
        if (!is.na(footer_start)) {
          clean_text <- str_sub(clean_text, 1, footer_start - 1)
        }
        clean_text <- str_trim(clean_text)
        pattern <- "(\\d{3}|XXX|\\?\\?\\?)\\s+(\\d{2}/\\d{2}/\\d{2})\\b"
        matches <- str_locate_all(clean_text, pattern)[[1]]
        yy <- str_sub(year, 3, 4)
        date_pattern <- paste0("\\d{2}/\\d{2}/", yy)
        for (i in 1:nrow(matches)) {
          start <- matches[i, "start"]
          end <- if (i < nrow(matches)) matches[i+1, "start"] - 1 else nchar(clean_text)
          line <- str_trim(str_sub(clean_text, start, end))
          matched <- str_match(line, pattern)
          number <- matched[1,2]
          date <- matched[1,3]
          if (!str_detect(date, paste0("/", yy, "$"))) next
          month <- as.integer(str_sub(date, 1, 2))
          desc_start <- str_length(matched[1,1])
          description <- str_trim(str_sub(line, desc_start + 1))
          has_camera <- str_detect(line, "(?i)\\b\\d+\\s*cameras?\\b")
          is_closed <- str_detect(line, "(?i)\\bclosed\\b")
          all_entries <- add_row(all_entries, year = year, number = number, date = date, 
                                 month = month, has_camera = has_camera, is_closed = is_closed, 
                                 description = description)
        }
      }, error = function(e) {
        message("Error fetching or parsing year ", year, ": ", e$message)
      })
    }
    all_entries
  })

  output$yearlyPlot <- renderPlot({
    df <- data() %>% group_by(year) %>% summarise(count = n())
    if (nrow(df) == 0) return(NULL)
    ggplot(df, aes(x = year, y = count)) + geom_bar(stat = "identity") + 
      theme_minimal() + labs(title = "Homicides per Year")
  })

  output$monthlyPlot <- renderPlot({
    df <- data() %>% group_by(year, month) %>% summarise(count = n(), .groups = "drop")
    if (nrow(df) == 0) return(NULL)
    ggplot(df, aes(x = factor(month), y = count, fill = year)) + 
      geom_bar(stat = "identity", position = "dodge") + 
      theme_minimal() + labs(title = "Monthly Homicides", x = "Month")
  })

  output$totalBox <- renderValueBox({
    total <- nrow(data())
    valueBox(total, "Total Homicides", color = "red")
  })

  output$closureRateBox <- renderValueBox({
    closed <- sum(data()$is_closed)
    rate <- if (nrow(data()) > 0) round(closed / nrow(data()) * 100, 1) else 0
    valueBox(paste(rate, "%"), "Overall Closure Rate", color = "blue")
  })

  output$cameraClosureBox <- renderValueBox({
    with_cam <- data() %>% filter(has_camera)
    closed_cam <- sum(with_cam$is_closed)
    rate_cam <- if (nrow(with_cam) > 0) round(closed_cam / nrow(with_cam) * 100, 1) else 0
    valueBox(paste(rate_cam, "%"), "Closure Rate with Cameras", color = "green")
  })

  output$dataTable <- renderDT({
    data() %>% select(year, number, date, description, has_camera, is_closed)
  })
}

shinyApp(ui, server)