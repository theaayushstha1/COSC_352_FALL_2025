FROM rocker/shiny:4.4.1

RUN install2.r --error \
    rvest \
    dplyr \
    tidyr \
    stringr \
    lubridate \
    DT \
    ggplot2 \
    purrr \
    tibble

WORKDIR /srv/shiny-server
COPY app.R /srv/shiny-server/app.R

EXPOSE 3838
