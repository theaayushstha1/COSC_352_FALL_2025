FROM rocker/shiny:latest

# system deps (add as needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libxml2-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# copy app
RUN mkdir -p /srv/shiny-server/project7
COPY . /srv/shiny-server/project7
WORKDIR /srv/shiny-server/project7

# install R packages
RUN R -e "install.packages(c('shiny','rvest','tidyverse','DT','lubridate'), repos='https://cran.rstudio.com')"

# run data fetch during build to pre-populate data
RUN Rscript data-fetch.R || true

EXPOSE 3838

# The rocker/shiny image runs shiny-server by default; keep default CMD
