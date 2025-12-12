library(shiny)
library(ggplot2)
library(dplyr)
library(DT)
library(lubridate)

# Load data with error handling
load_data <- function() {
  tryCatch({
    data <- read.csv("data/homicides_combined.csv", stringsAsFactors = FALSE)
    
    # Convert date column to proper format
    data$date <- as.Date(data$date)
    
    # Extract year from date
    data$year <- year(data$date)
    
    # Handle missing values
    data[is.na(data)] <- "Unknown"
    
    return(data)
  }, error = function(e) {
    # If file doesn't exist, create sample data
    data.frame(
      date = as.Date(c("2024-01-01", "2024-02-01")),
      victim_name = c("Sample 1", "Sample 2"),
      age = c(25, 30),
      race = c("Black", "White"),
      sex = c("Male", "Female"),
      location = c("100 Block Main St", "200 Block Park Ave"),
      district = c("Central", "Eastern"),
      cause = c("Shooting", "Stabbing"),
      near_camera = c("Yes", "No"),
      arrest_made = c("No", "Yes"),
      year = c(2024, 2024)
    )
  })
}

# Load the data
homicides <- load_data()

# UI
ui <- fluidPage(
  titlePanel("Baltimore City Homicides Dashboard (2021-2025)"),
  
  sidebarLayout(
    sidebarPanel(
      h3("Filters"),
      selectInput("year_filter", 
                  "Select Year:", 
                  choices = c("All", sort(unique(homicides$year), decreasing = TRUE))),
      
      selectInput("district_filter", 
                  "Select District:", 
                  choices = c("All", sort(unique(homicides$district)))),
      
      hr(),
      h4("Data Summary"),
      textOutput("total_count"),
      br(),
      p("Data Source: ChamsPage Blog"),
      p("Created for COSC Project 7")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Overview", 
                 h3("Homicides by Year"),
                 plotOutput("yearlyPlot", height = "300px"),
                 hr(),
                 h3("Homicides by District"),
                 plotOutput("districtPlot", height = "300px"),
                 hr(),
                 h3("Demographics"),
                 plotOutput("agePlot", height = "300px")
        ),
        
        tabPanel("Monthly Trends", 
                 plotOutput("monthlyPlot", height = "400px")
        ),
        
        tabPanel("Data Table", 
                 DTOutput("dataTable")
        ),
        
        tabPanel("Statistics",
                 h3("Summary Statistics"),
                 verbatimTextOutput("summary_stats"),
                 hr(),
                 h3("Arrests"),
                 plotOutput("arrestPlot", height = "300px")
        )
      )
    )
  )
)

# Server
server <- function(input, output) {
  
  # Filtered data reactive
  filtered_data <- reactive({
    data <- homicides
    
    # Filter by year
    if(input$year_filter != "All") {
      data <- data %>% filter(year == as.numeric(input$year_filter))
    }
    
    # Filter by district
    if(input$district_filter != "All") {
      data <- data %>% filter(district == input$district_filter)
    }
    
    return(data)
  })
  
  # Total count display
  output$total_count <- renderText({
    paste("Total Homicides:", nrow(filtered_data()))
  })
  
  # Yearly trend plot
  output$yearlyPlot <- renderPlot({
    data_summary <- homicides %>%
      group_by(year) %>%
      summarise(count = n(), .groups = 'drop')
    
    ggplot(data_summary, aes(x = factor(year), y = count)) +
      geom_col(fill = "steelblue") +
      geom_text(aes(label = count), vjust = -0.5) +
      theme_minimal() +
      labs(title = "Total Homicides by Year",
           x = "Year",
           y = "Number of Homicides") +
      theme(text = element_text(size = 14))
  })
  
  # District plot
  output$districtPlot <- renderPlot({
    data_summary <- filtered_data() %>%
      group_by(district) %>%
      summarise(count = n(), .groups = 'drop') %>%
      arrange(desc(count))
    
    ggplot(data_summary, aes(x = reorder(district, count), y = count)) +
      geom_col(fill = "coral") +
      coord_flip() +
      geom_text(aes(label = count), hjust = -0.2) +
      theme_minimal() +
      labs(title = "Homicides by District",
           x = "District",
           y = "Number of Homicides") +
      theme(text = element_text(size = 14))
  })
  
  # Age distribution
  output$agePlot <- renderPlot({
    data <- filtered_data() %>%
      filter(age != "Unknown" & !is.na(age))
    
    if(nrow(data) > 0) {
      ggplot(data, aes(x = as.numeric(age))) +
        geom_histogram(bins = 20, fill = "darkgreen", color = "white") +
        theme_minimal() +
        labs(title = "Age Distribution of Victims",
             x = "Age",
             y = "Count") +
        theme(text = element_text(size = 14))
    }
  })
  
  # Monthly trends
  output$monthlyPlot <- renderPlot({
    data <- filtered_data() %>%
      mutate(month = month(date, label = TRUE))
    
    data_summary <- data %>%
      group_by(year, month) %>%
      summarise(count = n(), .groups = 'drop')
    
    ggplot(data_summary, aes(x = month, y = count, group = year, color = factor(year))) +
      geom_line(size = 1.2) +
      geom_point(size = 2) +
      theme_minimal() +
      labs(title = "Monthly Homicide Trends",
           x = "Month",
           y = "Number of Homicides",
           color = "Year") +
      theme(text = element_text(size = 14),
            axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  # Arrest statistics
  output$arrestPlot <- renderPlot({
    data_summary <- filtered_data() %>%
      group_by(arrest_made) %>%
      summarise(count = n(), .groups = 'drop')
    
    ggplot(data_summary, aes(x = arrest_made, y = count, fill = arrest_made)) +
      geom_col() +
      geom_text(aes(label = count), vjust = -0.5) +
      scale_fill_manual(values = c("Yes" = "darkgreen", "No" = "darkred")) +
      theme_minimal() +
      labs(title = "Arrests Made",
           x = "Arrest Status",
           y = "Count") +
      theme(text = element_text(size = 14), legend.position = "none")
  })
  
  # Summary statistics
  output$summary_stats <- renderPrint({
    data <- filtered_data()
    cat("Total Homicides:", nrow(data), "\n")
    cat("\nBy Race:\n")
    print(table(data$race))
    cat("\nBy Sex:\n")
    print(table(data$sex))
    cat("\nBy Cause:\n")
    print(table(data$cause))
    cat("\nAverage Age:", mean(as.numeric(data$age[data$age != "Unknown"]), na.rm = TRUE), "\n")
  })
  
  # Data table
  output$dataTable <- renderDT({
    datatable(filtered_data(), 
              options = list(pageLength = 25, scrollX = TRUE),
              rownames = FALSE)
  })
}

# Run the app
shinyApp(ui = ui, server = server)
