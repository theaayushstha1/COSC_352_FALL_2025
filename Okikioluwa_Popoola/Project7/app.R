library(shiny)
library(dplyr)
library(ggplot2)
library(DT)
library(lubridate)
library(readr)

df <- read_csv("data/homicides_clean.csv")

ui <- fluidPage(
  titlePanel("Baltimore City Homicide Dashboard (2021–2025)"),
  sidebarLayout(
    sidebarPanel(
      selectInput("year", "Year:", choices = sort(unique(df$year)), selected = "2025"),
      selectInput("method", "Method:", choices = c("All", unique(df$method))),
      selectInput("gender", "Gender:", choices = c("All", "Male", "Female"))
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Overview", plotOutput("homicidePlot")),
        tabPanel("Data Table", DTOutput("table"))
      )
    )
  )
)

server <- function(input, output) {
  filtered <- reactive({
    data <- df %>% filter(year == input$year)
    if (input$method != "All") data <- data %>% filter(method == input$method)
    if (input$gender != "All") data <- data %>% filter(gender == input$gender)
    data
  })

  output$homicidePlot <- renderPlot({
    filtered() %>%
      mutate(month = month(date, label = TRUE)) %>%
      count(month) %>%
      ggplot(aes(month, n)) +
      geom_col() +
      theme_minimal() +
      labs(title = paste("Homicides per Month in", input$year))
  })

  output$table <- renderDT({ filtered() })
}

shinyApp(ui, server)
