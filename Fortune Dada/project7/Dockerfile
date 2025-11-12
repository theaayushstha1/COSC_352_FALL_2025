FROM rocker/shiny:latest

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev libssl-dev libxml2-dev libfontconfig1-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('shiny','tidyverse','rvest','DT','lubridate','ggplot2','shinythemes','readr','stringr','purrr','tidyr'), repos='https://cloud.r-project.org')"

EXPOSE 3838

CMD ["/usr/bin/shiny-server","--no-daemonize"]
