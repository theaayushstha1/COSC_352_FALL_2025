FROM rocker/shiny:latest

# Install only the packages we actually use
RUN R -e "install.packages(c('shiny','rvest','dplyr','readr','ggplot2','stringr','purrr','DT'), repos='https://cran.rstudio.com/')"

# Copy app into Shiny Server directory
COPY . /srv/shiny-server/
