library(shiny)
library(dplyr)
library(readr)
library(ggplot2)
library(stringr)

ui <- fluidPage(
  titlePanel("Baltimore Homicides Dashboard"),

  sidebarLayout(
    sidebarPanel(
      selectInput("year", "Select Year:",
                  choices = c("All", 2022:2025),
                  selected = "All")
    ),

    mainPanel(
      tabsetPanel(
        tabPanel("Data Table", dataTableOutput("table")),
        tabPanel("Monthly Trends", plotOutput("monthlyPlot"))
      )
    )
  )
)

server <- function(input, output, session) {

  data <- reactive({
    # Load the combined CSV
    df <- read_csv("homicides_all.csv")

    if (input$year != "All") {
      df <- df %>% filter(year == input$year)
    }

    df
  })

  output$table <- renderDataTable({
    data()
  })

  output$monthlyPlot <- renderPlot({
    df <- data()

    # Try to detect month column (differs by year)
    month_col <- names(df)[str_detect(names(df), "month")][1]

    if (is.null(month_col)) return(NULL)

    df %>%
      count(!!sym(month_col)) %>%
      ggplot(aes(x = !!sym(month_col), y = n)) +
      geom_bar(stat = "identity") +
      labs(x = "Month", y = "Homicides", title = "Homicides per Month") +
      theme_minimal()
  })
}

shinyApp(ui, server)
