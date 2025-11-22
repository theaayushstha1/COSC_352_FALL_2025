FROM rocker/shiny:latest

# Install R packages your app needs
RUN install2.r --error \
    shiny \
    bslib \
    rvest \
    dplyr \
    stringr \
    tibble \
    ggplot2

# Copy Shiny app into the container
COPY app.R /srv/shiny-server/app.R

# Expose Shiny port
EXPOSE 3838

# rocker/shiny already has CMD to start shiny-server
