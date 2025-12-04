# Use the Rocker Shiny base image, which has R + Shiny Server preinstalled
FROM rocker/shiny:4.4.1

# Install the R packages your app uses
RUN install2.r --error \
    shinythemes \
    tidyverse \
    lubridate \
    DT \
    rvest

# Set the working directory where the app will live inside the container
WORKDIR /srv/shiny-server/baltimore-homicides

# Copy the Shiny app file into the container
COPY app.R .

# Copy the pre-scraped CSV into the container
COPY all_homicides.csv .

# (Optional) copy scraper if you want it in the image for debugging/manual runs
COPY scrape.R .

# Expose the Shiny Server default port
EXPOSE 3838

# Start Shiny Server
CMD ["/usr/bin/shiny-server"]
