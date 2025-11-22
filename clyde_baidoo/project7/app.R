# app.R
library(shiny)
library(rvest)
library(lubridate)
library(DT)
library(leaflet)
library(plotly)
library(tidygeocoder)
library(sf)
library(stringr)

pages <- data.frame(
  year = 2021:2025,
  url = c(
    "http://chamspage.blogspot.com/2021/",
    "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
    "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
    "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
    "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
  ),
  stringsAsFactors = FALSE
)

cache_dir <- "data/raw"
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

fetch_page_cached <- function(url) {
  file <- file.path(cache_dir, paste0(gsub("[^0-9A-Za-z]", "_", url), ".html"))
  if (!file.exists(file)) {
    try({
      read <- xml2::read_html(url)
      xml2::write_html(read, file)
    }, silent = TRUE)
  }
  xml2::read_html(file)
}

parse_chamspage <- function(page_html, year) {
  tables <- html_nodes(page_html, "table")
  parsed_rows <- list()
  
  if(length(tables) > 0) {
    for(tbl in tables) {
      rows <- html_nodes(tbl, "tr")
      for(r in rows) {
        cells <- html_text(html_nodes(r, "td"))
        parsed_rows[[length(parsed_rows)+1]] <- data.frame(
          date = if(length(cells)>=2) cells[2] else NA,
          name = if(length(cells)>=3) cells[3] else NA,
          address = if(length(cells)>=4) cells[4] else NA,
          notes = if(length(cells)>=5) cells[5] else if(length(cells)>=1) cells[1] else NA,
          source_year = year,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  
  if(length(parsed_rows) == 0) {
    body_nodes <- html_nodes(page_html, "div.post-body, .post-body, .entry-content")
    body <- if(length(body_nodes) > 0) html_text2(body_nodes) else html_text2(page_html)
    lines <- str_trim(unlist(strsplit(body, "\n")))
    rows <- lines[grepl("\\d{1,2}/\\d{1,2}/\\d{2,4}", lines)]
    
    for(r in rows) {
      date_match <- regmatches(r, regexpr("\\d{1,2}/\\d{1,2}/\\d{2,4}", r))
      name_match <- sub("^\\d+\\s+\\d{1,2}/\\d{1,2}/\\d{2,4}\\s+([^,\\d]{2,100}).*$", "\\1", r)
      addr_match <- regmatches(r, regexpr("\\d{1,5}\\s+[A-Za-z0-9\\.#\\-\\s]{3,100}", r))
      
      parsed_rows[[length(parsed_rows)+1]] <- data.frame(
        date = if(length(date_match)==0) NA else date_match,
        name = if(length(name_match)==0) NA else str_trim(name_match),
        address = if(length(addr_match)==0) NA else str_trim(addr_match),
        notes = r,
        source_year = year,
        stringsAsFactors = FALSE
      )
    }
  }
  
  if(length(parsed_rows)==0) return(data.frame(date=NA, name=NA, address=NA, notes=NA, source_year=year, stringsAsFactors=FALSE))
  
  df <- do.call(rbind, parsed_rows)

  df$date <- as.Date(parse_date_time(df$date, orders=c("mdy","dmy","ymd"), quiet=TRUE))
  df
}

load_all <- function() {
  all_data <- list()
  for(i in 1:nrow(pages)) {
    html <- fetch_page_cached(pages$url[i])
    df <- parse_chamspage(html, pages$year[i])
    all_data[[length(all_data)+1]] <- df
  }
  do.call(rbind, all_data)
}

geocode_if_needed <- function(df, force=FALSE) {
  dir.create("data", showWarnings = FALSE)
  gfile <- "data/geocoded.csv"
  if(file.exists(gfile) && !force) {
    geo <- read.csv(gfile, stringsAsFactors=FALSE)
  } else {
    addresses <- unique(na.omit(df$address))
    if(length(addresses)==0) return(data.frame(address=character(), latitude=numeric(), longitude=numeric(), stringsAsFactors=FALSE))
    geo <- geocode(addresses, method="osm", lat="latitude", long="longitude", timeout=60, full_results=FALSE)
    write.csv(geo, gfile, row.names=FALSE)
  }
  geo
}

all_data <- load_all()
if(file.exists("data/geocoded.csv") && nrow(all_data)>0) {
  geo <- read.csv("data/geocoded.csv", stringsAsFactors=FALSE)
  all_data <- merge(all_data, geo, by.x="address", by.y="address", all.x=TRUE)
}

ui <- fluidPage(
  titlePanel("Baltimore City Homicide Lists — 2021–2025"),
  sidebarLayout(
    sidebarPanel(
      helpText("Data sourced from Chamspage homicide lists."),
      checkboxInput("include_geocode", "Enable geocoding (API calls if no cache)", value=FALSE),
      actionButton("do_geocode", "Run geocode now"),
      hr(),
      dateRangeInput("daterange", "Date range", start=min(all_data$date, na.rm=TRUE), end=max(all_data$date, na.rm=TRUE)),
      textInput("namefilter", "Name contains", value=""),
      selectInput("yearfilter", "Year", choices=c("All", sort(unique(all_data$source_year))), selected="All"),
      downloadButton("download_csv", "Download filtered CSV")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Map", leafletOutput("map", height=600)),
        tabPanel("Trend", plotlyOutput("trend_plot", height=400)),
        tabPanel("Table", DTOutput("table"))
      )
    )
  )
)

server <- function(input, output, session) {
  
  df_reactive <- reactive({
    df <- all_data
    if(input$yearfilter!="All") df <- df[df$source_year==as.integer(input$yearfilter),]
    if(nzchar(input$namefilter)) df <- df[grepl(tolower(input$namefilter), tolower(df$name)),]
    if(!is.null(input$daterange)) df <- df[is.na(df$date) | (df$date>=input$daterange[1] & df$date<=input$daterange[2]),]
    df
  })
  
  observeEvent(input$do_geocode, {
    req(input$include_geocode)
    showModal(modalDialog("Geocoding in progress...", footer=modalButton("OK")))
    df <- df_reactive()
    geo <- geocode_if_needed(df, force=FALSE)
    all_data <<- merge(all_data, geo, by.x="address", by.y="address", all.x=TRUE)
    removeModal()
  })
  
  output$table <- renderDT({
    dat <- df_reactive()
    dat$date <- as.character(dat$date)
    dat[, c("date","source_year","name","address","notes")]
  }, options=list(pageLength=25))
  
  output$trend_plot <- renderPlotly({
    dat <- df_reactive()
    dat <- dat[!is.na(dat$date),]
    if(nrow(dat)==0) return(NULL)
    dat$month <- as.Date(format(dat$date, "%Y-%m-01"))
    counts <- aggregate(list(n=dat$month), by=list(month=dat$month), FUN=length)
    p <- ggplot2::ggplot(counts, ggplot2::aes(x=month, y=n)) + ggplot2::geom_line() + ggplot2::geom_point() +
      ggplot2::labs(x="Month", y="Homicides", title="Homicides over time")
    plotly::ggplotly(p)
  })
  
  output$map <- renderLeaflet({
    dat <- df_reactive()
    dat_map <- dat[!is.na(dat$latitude) & !is.na(dat$longitude),]
    m <- leaflet() %>% addTiles()
    if(nrow(dat_map)>0){
      m <- m %>% addCircleMarkers(lng=dat_map$longitude, lat=dat_map$latitude, radius=6,
                                 popup=paste0("<b>", dat_map$name, "</b><br/>Date: ", dat_map$date,
                                              "<br/>Address: ", dat_map$address))
    } else {
      m <- m %>% addPopups(lng=-76.61, lat=39.29, "No geocoded points available. Enable geocoding and run it.")
    }
    m
  })
  
  output$download_csv <- downloadHandler(
    filename = function(){ paste0("homicides_filtered_", Sys.Date(), ".csv") },
    content = function(file){ write.csv(df_reactive(), file, row.names=FALSE) }
  )
}

shinyApp(ui, server)
