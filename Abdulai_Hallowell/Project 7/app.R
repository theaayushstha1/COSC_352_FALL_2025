library(shiny)
library(tidyverse)
library(DT)

# Load cleaned dataset
homicides <- read_csv("data/homicides_clean.csv")

ui <- fluidPage(
  titlePanel("Baltimore Homicides Dashboard"),

  sidebarLayout(
    sidebarPanel(
      h4("Filters"),
      selectInput(
        "year",
        "Select Year:",
        choices = sort(unique(homicides$year)),
        selected = max(homicides$year)
      )
    ),

    mainPanel(
      tabsetPanel(
        tabPanel("Table",
                 br(),
                 DTOutput("table")
        ),
        tabPanel("Homicides by Year",
                 br(),
                 plotOutput("yearPlot", height = "500px")
        )
      )
    )
  )
)

server <- function(input, output) {

  # Filter table by selected year
  filtered <- reactive({
    homicides %>% filter(year == input$year)
  })

  # Data table of homicide text for that year
  output$table <- DT::renderDT({
    filtered()
  })

  # Simple bar chart: count of homicide entries per year
  output$yearPlot <- renderPlot({
    homicides %>%
      count(year) %>%
      ggplot(aes(x = factor(year), y = n)) +
      geom_col() +
      labs(
        x = "Year",
        y = "Number of homicide entries (approx.)",
        title = "Baltimore homicide entries by year (from Cham's Page scrape)"
      ) +
      theme_minimal()
  })
}

shinyApp(ui, server)
