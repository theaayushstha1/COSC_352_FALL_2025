# Project 7 — Baltimore City Homicide Dashboard

Run:
Rscript data_scrape.R
Rscript clean_data.R
docker build -t homicide-dashboard .
docker run -p 3838:3838 homicide-dashboard
