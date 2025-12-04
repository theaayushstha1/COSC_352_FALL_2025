FROM rocker/shiny:latest
RUN apt-get update && apt-get install -y libxml2-dev libcurl4-openssl-dev libssl-dev && rm -rf /var/lib/apt/lists/*
COPY . /srv/shiny-server/project8
WORKDIR /srv/shiny-server/project8
RUN R -e "install.packages(c('shiny','rvest','dplyr','lubridate','purrr','readr','stringr','leaflet','DT','ggplot2'))"
EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
