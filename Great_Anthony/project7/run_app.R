# Script to run the Shiny application

library(shiny)

# Run the app on port 8080
runApp("app.R", host = "0.0.0.0", port = 8080, launch.browser = FALSE)
