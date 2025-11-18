FROM rocker/shiny:latest
RUN R -e "install.packages(c('shiny','rvest','dplyr','stringr','readr','purrr','DT','lubridate','ggplot2'))"
COPY . /srv/shiny-server/
EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
