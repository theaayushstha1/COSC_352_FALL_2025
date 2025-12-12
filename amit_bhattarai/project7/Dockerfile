FROM --platform=linux/amd64 rocker/shiny:4.3.1

RUN install2.r --error \
    rvest \
    janitor \
    lubridate \
    DT \
    tidyverse

WORKDIR /srv/shiny-server
COPY . /srv/shiny-server/
RUN chown -R shiny:shiny /srv/shiny-server

EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
