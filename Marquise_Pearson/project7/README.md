# Baltimore City Homicides Dashboard (2021–2025)

This project uses **R** and **RShiny** to scrape and visualize Baltimore City homicide
data from chamspage.blogspot.com for the years 2021–2025.

## Data sources

- 2021: https://chamspage.blogspot.com/2021/
- 2022: https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html
- 2023: https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html
- 2024: https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html
- 2025: https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html

The app scrapes the HTML tables from these pages at runtime and builds a unified dataset.

## How to run with Docker (inside Codespace or locally)

 Build the image:

   ```bash
   docker build -t bmore-homicides-rshiny 

Run the Docker Container
   In the terminal, start the app:
   docker run -p 3838:3838 bmore-homicides-rshiny

If successful, you will see:
   Listening on http://0.0.0.0:3838


Open the Shiny Dashboard in Your Browser
   In GitHub Codespaces, click the PORTS tab at the bottom.
   Find port 3838 in the table.
   Click the URL shown in the Forwarded Address column:
   https://<your-codespace-id>-3838.github.dev
   The dashboard will open in a new browser tab.
   You can now interact with all charts, filters, and tables.

Stop the App
   When you are finished:
   Go back to the terminal running Docker
   Press CTRL + C
   This stops the Shiny server and exits the container.