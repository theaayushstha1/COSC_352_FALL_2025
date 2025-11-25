# Baltimore City Homicide Dashboard
# RShiny Application

library(shiny)
library(dplyr)
library(ggplot2)
library(lubridate)
library(DT)
library(plotly)
library(tidyr)

# Load data
load_data <- function() {
  if (file.exists("data/homicides.csv")) {
    data <- read.csv("data/homicides.csv", stringsAsFactors = FALSE)
    return(data)
  } else {
    # Return sample data if file doesn't exist
    return(data.frame(
      Year = rep(2021:2025, each = 50),
      Month = sample(1:12, 250, replace = TRUE),
      Victim = paste("Victim", 1:250),
      Age = sample(15:75, 250, replace = TRUE),
      Race = sample(c("Black", "White", "Hispanic", "Asian", "Other"), 250, replace = TRUE),
      Gender = sample(c("Male", "Female"), 250, replace = TRUE),
      Location = paste("Location", 1:250),
      Cause = sample(c("Shooting", "Stabbing", "Blunt Force", "Other"), 250, replace = TRUE)
    ))
  }
}

homicide_data <- load_data()

# UI
ui <- fluidPage(
  titlePanel("Baltimore City Homicide Dashboard (2021-2025)"),
  
  theme = bslib::bs_theme(bootswatch = "darkly"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Filters"),
      
      selectInput("year_filter", 
                  "Select Year(s):", 
                  choices = c("All", unique(sort(homicide_data$Year))),
                  selected = "All",
                  multiple = TRUE),
      
      hr(),
      
      h5("Dashboard Information"),
      p("This dashboard visualizes Baltimore City homicide data from 2021 to 2025."),
      p(paste("Total Records:", nrow(homicide_data))),
      
      hr(),
      
      downloadButton("download_data", "Download Data")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Overview",
                 fluidRow(
                   column(4, 
                          h4("Key Statistics"),
                          verbatimTextOutput("stats_summary")
                   ),
                   column(8,
                          plotlyOutput("yearly_trend", height = "300px")
                   )
                 ),
                 hr(),
                 fluidRow(
                   column(6,
                          plotlyOutput("monthly_pattern", height = "300px")
                   ),
                   column(6,
                          plotlyOutput("demographics_plot", height = "300px")
                   )
                 )
        ),
        
        tabPanel("Yearly Analysis",
                 plotlyOutput("yearly_comparison", height = "400px"),
                 hr(),
                 plotlyOutput("yearly_breakdown", height = "400px")
        ),
        
        tabPanel("Demographics",
                 fluidRow(
                   column(6,
                          plotlyOutput("age_distribution", height = "350px")
                   ),
                   column(6,
                          plotlyOutput("gender_race_plot", height = "350px")
                   )
                 ),
                 hr(),
                 plotlyOutput("cause_analysis", height = "300px")
        ),
        
        tabPanel("Geographic Analysis",
                 h4("Location Analysis"),
                 plotlyOutput("location_plot", height = "500px")
        ),
        
        tabPanel("Data Table",
                 h4("Complete Dataset"),
                 DTOutput("data_table")
        ),
        
        tabPanel("About",
                 h3("About This Dashboard"),
                 p("This interactive dashboard presents Baltimore City homicide data from 2021 to 2025."),
                 h4("Data Source"),
                 p("Data is collected from Justin Fenton's Chams Page blog, which maintains detailed records of Baltimore homicides."),
                 h4("Features"),
                 tags$ul(
                   tags$li("Yearly trend analysis"),
                   tags$li("Monthly patterns"),
                   tags$li("Demographic breakdowns"),
                   tags$li("Geographic analysis"),
                   tags$li("Interactive filtering and data download")
                 ),
                 h4("Technologies"),
                 p("Built with R and RShiny, using ggplot2, plotly, and DT for visualizations.")
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive filtered data
  filtered_data <- reactive({
    data <- homicide_data
    
    if (!"All" %in% input$year_filter && !is.null(input$year_filter)) {
      data <- data %>% filter(Year %in% input$year_filter)
    }
    
    return(data)
  })
  
  # Statistics summary
  output$stats_summary <- renderText({
    data <- filtered_data()
    paste(
      "Total Homicides:", nrow(data), "\n",
      "Years Covered:", paste(range(data$Year), collapse = " - "), "\n",
      "Average per Year:", round(nrow(data) / length(unique(data$Year)), 1)
    )
  })
  
  # Yearly trend
  output$yearly_trend <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Year) %>%
      summarise(Count = n())
    
    p <- ggplot(data, aes(x = Year, y = Count)) +
      geom_line(color = "#2E86AB", size = 1.5) +
      geom_point(color = "#A23B72", size = 3) +
      labs(title = "Homicides by Year", x = "Year", y = "Number of Homicides") +
      theme_minimal() +
      theme(plot.title = element_text(face = "bold"))
    
    ggplotly(p)
  })
  
  # Monthly pattern
  output$monthly_pattern <- renderPlotly({
    if ("Month" %in% names(filtered_data())) {
      data <- filtered_data() %>%
        group_by(Month) %>%
        summarise(Count = n()) %>%
        mutate(Month_Name = month.abb[Month])
      
      p <- ggplot(data, aes(x = reorder(Month_Name, Month), y = Count)) +
        geom_bar(stat = "identity", fill = "#F18F01") +
        labs(title = "Homicides by Month", x = "Month", y = "Count") +
        theme_minimal() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
      
      ggplotly(p)
    }
  })
  
  # Demographics plot
  output$demographics_plot <- renderPlotly({
    if ("Race" %in% names(filtered_data())) {
      data <- filtered_data() %>%
        group_by(Race) %>%
        summarise(Count = n())
      
      p <- ggplot(data, aes(x = reorder(Race, -Count), y = Count, fill = Race)) +
        geom_bar(stat = "identity") +
        labs(title = "Homicides by Race", x = "Race", y = "Count") +
        theme_minimal() +
        theme(legend.position = "none")
      
      ggplotly(p)
    }
  })
  
  # Yearly comparison
  output$yearly_comparison <- renderPlotly({
    data <- filtered_data() %>%
      group_by(Year) %>%
      summarise(Count = n())
    
    p <- ggplot(data, aes(x = factor(Year), y = Count, fill = factor(Year))) +
      geom_bar(stat = "identity") +
      labs(title = "Year-over-Year Comparison", x = "Year", y = "Number of Homicides") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  # Yearly breakdown
  output$yearly_breakdown <- renderPlotly({
    if ("Month" %in% names(filtered_data())) {
      data <- filtered_data() %>%
        group_by(Year, Month) %>%
        summarise(Count = n(), .groups = "drop")
      
      p <- ggplot(data, aes(x = Month, y = Count, color = factor(Year), group = Year)) +
        geom_line(size = 1) +
        geom_point() +
        labs(title = "Monthly Trends by Year", x = "Month", y = "Count", color = "Year") +
        theme_minimal()
      
      ggplotly(p)
    }
  })
  
  # Age distribution
  output$age_distribution <- renderPlotly({
    if ("Age" %in% names(filtered_data())) {
      data <- filtered_data()
      
      p <- ggplot(data, aes(x = Age)) +
        geom_histogram(bins = 30, fill = "#06A77D", color = "white") +
        labs(title = "Age Distribution of Victims", x = "Age", y = "Count") +
        theme_minimal()
      
      ggplotly(p)
    }
  })
  
  # Gender and race
  output$gender_race_plot <- renderPlotly({
    if (all(c("Gender", "Race") %in% names(filtered_data()))) {
      data <- filtered_data() %>%
        group_by(Gender, Race) %>%
        summarise(Count = n(), .groups = "drop")
      
      p <- ggplot(data, aes(x = Race, y = Count, fill = Gender)) +
        geom_bar(stat = "identity", position = "dodge") +
        labs(title = "Gender and Race Distribution", x = "Race", y = "Count") +
        theme_minimal() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
      
      ggplotly(p)
    }
  })
  
  # Cause analysis
  output$cause_analysis <- renderPlotly({
    if ("Cause" %in% names(filtered_data())) {
      data <- filtered_data() %>%
        group_by(Cause) %>%
        summarise(Count = n())
      
      p <- ggplot(data, aes(x = reorder(Cause, -Count), y = Count, fill = Cause)) +
        geom_bar(stat = "identity") +
        labs(title = "Homicides by Cause", x = "Cause of Death", y = "Count") +
        theme_minimal() +
        theme(legend.position = "none")
      
      ggplotly(p)
    }
  })
  
  # Location plot
  output$location_plot <- renderPlotly({
    if ("Location" %in% names(filtered_data())) {
      data <- filtered_data() %>%
        group_by(Location) %>%
        summarise(Count = n()) %>%
        arrange(desc(Count)) %>%
        head(20)
      
      p <- ggplot(data, aes(x = reorder(Location, Count), y = Count)) +
        geom_bar(stat = "identity", fill = "#C73E1D") +
        coord_flip() +
        labs(title = "Top 20 Locations", x = "Location", y = "Count") +
        theme_minimal()
      
      ggplotly(p)
    }
  })
  
  # Data table
  output$data_table <- renderDT({
    datatable(filtered_data(), 
              options = list(pageLength = 25, scrollX = TRUE),
              filter = 'top')
  })
  
  # Download handler
  output$download_data <- downloadHandler(
    filename = function() {
      paste("baltimore_homicides_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(filtered_data(), file, row.names = FALSE)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)
