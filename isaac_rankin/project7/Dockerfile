FROM rocker/shiny:latest

# Install R packages
RUN install2.r --error \
    shiny \
    rvest \
    dplyr \
    stringr \
    readr \
    ggplot2 \
    purrr

# Copy app into Shiny Server directory
COPY app.R /srv/shiny-server/app/app.R
COPY scrape_and_clean.R /srv/shiny-server/app/scrape_and_clean.R

# Generate CSV files inside the container
RUN Rscript /srv/shiny-server/app/scrape_and_clean.R

# Permissions
RUN chown -R shiny:shiny /srv/shiny-server

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
