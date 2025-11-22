FROM rocker/shiny:latest

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgdal-dev \
    libudunits2-dev \
    libproj-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('shiny', 'shinydashboard', 'rvest', 'dplyr', 'tidyr', 'ggplot2', 'lubridate', 'DT', 'plotly', 'leaflet', 'stringr'), repos='https://cran.rstudio.com/')"

RUN mkdir -p /srv/shiny-server/baltimore-homicides

COPY app.R /srv/shiny-server/baltimore-homicides/

RUN chmod -R 755 /srv/shiny-server/baltimore-homicides

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
