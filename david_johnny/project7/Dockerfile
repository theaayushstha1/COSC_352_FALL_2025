FROM rocker/shiny:4.3.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages (install tidyverse components individually for reliability)
RUN R -e "install.packages(c('shiny', 'dplyr', 'tidyr', 'purrr', 'stringr', 'ggplot2', 'readr', 'rvest', 'lubridate', 'DT', 'plotly'), repos='https://cran.rstudio.com/')"

# Create app directory
RUN mkdir -p /srv/shiny-server/baltimore-homicides

# Copy app files
COPY app.R /srv/shiny-server/baltimore-homicides/

# Set permissions
RUN chown -R shiny:shiny /srv/shiny-server/baltimore-homicides

# Enable detailed error logging
RUN echo "preserve_logs true;" >> /etc/shiny-server/shiny-server.conf && \
    echo "sanitize_errors false;" >> /etc/shiny-server/shiny-server.conf

# Actually test if the app loads without errors (but don't try to run shinyApp)
RUN R -e "tryCatch({ \
    library(shiny); \
    library(dplyr); \
    library(tidyr); \
    library(purrr); \
    library(stringr); \
    library(ggplot2); \
    library(rvest); \
    library(lubridate); \
    library(DT); \
    library(plotly); \
    cat('Testing app syntax...\\n'); \
    parse('/srv/shiny-server/baltimore-homicides/app.R'); \
    cat('App syntax OK!\\n'); \
}, error = function(e) { \
    print(paste('ERROR:', e$message)); \
    quit(status=1); \
})"

# Expose port
EXPOSE 3838

# Run app
CMD ["/usr/bin/shiny-server"]