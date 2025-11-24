# app.R
library(shiny)
library(dplyr)
library(lubridate)
library(leaflet)
library(DT)
library(ggplot2)

data_file <- "data/processed/homicides_2021_2025.rds"
if (!file.exists(data_file)) {
  stop("Processed data not found. Run R/data_ingest.R")
}
h <- readRDS(data_file)
h <- h %>% mutate(year = year(date))

ui <- fluidPage(
  titlePanel("Baltimore City Homicides (2021–2025)"),
  sidebarLayout(
    sidebarPanel(
      selectInput("year","Year",choices=c("All", sort(unique(h$year))),selected="All"),
      checkboxInput("only_closed","Only Case Closed",FALSE),
      textInput("search_name","Search name/address",""),
      width=3
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Summary",
          fluidRow(
            column(4, wellPanel(h3(textOutput("total_count")), p("Total records shown"))),
            column(4, plotOutput("counts_by_month", height="250px")),
            column(4, plotOutput("age_dist", height="250px"))
          )
        ),
        tabPanel("Map", leafletOutput("map", height="600px")),
        tabPanel("Table", DTOutput("table"))
      )
    )
  )
)

server <- function(input, output, session) {
  df <- reactive({
    d <- h
    if (input$year!="All") d <- d %>% filter(year==as.integer(input$year))
    if (input$only_closed) d <- d %>% filter(!is.na(case_closed) & case_closed!="" & grepl("closed|yes|true", tolower(case_closed)))
    if (input$search_name!="") {
      q <- tolower(input$search_name)
      d <- d %>% filter(grepl(q, tolower(name)) | grepl(q, tolower(address_block)))
    }
    d
  })

  output$total_count <- renderText(nrow(df()))

  output$counts_by_month <- renderPlot({
    d <- df() %>% filter(!is.na(date)) %>% mutate(month=floor_date(date,"month")) %>% count(month)
    ggplot(d, aes(month,n)) + geom_col()
  })

  output$age_dist <- renderPlot({
    ages <- df() %>% filter(!is.na(as.numeric(age))) %>% mutate(age=as.numeric(age))
    if (nrow(ages)==0){ plot.new(); text(0.5,0.5,"No age data") }
    else ggplot(ages,aes(age)) + geom_histogram(bins=20)
  })

  output$map <- renderLeaflet({
    d <- df()
    if (!("lat" %in% names(d) && "lon" %in% names(d))) {
      leaflet() %>% addTiles() %>% addControl("No geocoded coordinates available.")
    } else {
      leaflet(d) %>% addTiles() %>% addCircleMarkers(~lon,~lat,popup=~paste0(name,"<br>",date,"<br>",address_block),clusterOptions=markerClusterOptions())
    }
  })

  output$table <- renderDT({
    df() %>% select(date,name,age,address_block,notes,camera,case_closed,source_url)
  }, options=list(pageLength=25, scrollX=TRUE))
}

shinyApp(ui, server)
