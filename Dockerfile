FROM rocker/shiny:latest

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
 && rm -rf /var/lib/apt/lists/*

COPY . /srv/shiny-server/

RUN R -e "install.packages(c('shiny','dplyr','rvest','lubridate','stringr','leaflet','DT','ggplot2','readr','purrr'), repos='https://cloud.r-project.org')"

EXPOSE 3838

CMD ["/usr/bin/shiny-server.sh"]
