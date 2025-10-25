Overview: 
The project analyzes Baltimore City homicide statistics by fetching data from a public website, process it using Python, and perform statistical analysis using Scala in a Docker container

How to run: 
1) Make the script executable: 
    chmod +x run.sh
2) Run the project: 
    ./run.sh

fetch_csv.py --> Python Script
Fetches and parses homicide data from the webpage
-- parses https://chamspage.blogspot.com/ using HTMLParser in Python 
-- extracts the table data from the HTML, includes all 9 columns
-- saves the data in chamspage_table1.csv
Connected requirements.txt file for the imported Python libraries used

article_questions.scala --> Scala Script
Analyzes the CSV data and answers key questions
-- reads chamspage_table1.csv, and parses the CSV 
-- Analyzes the data to answer the two questions
        
        What address blocks have the most repeated homicides? 
        -- groups homicides by location 
        -- identifies dangerous hotspots
        -- shows detailed breakdown of top locations
        WHY? --> It would help allocate police resources to high risk areas
        
        Which months have the highest homicide rates? 
        -- extracts month from date field
        -- counts homicides in the top months
        -- gives a sample of the victims within the top month
        WHY? --> Enables seasonal resource planning and prevention strategies during these top months

Dockerfile 
Creates a containerized environment to run the Scala program
-- installs scala 
-- copies scala, and csv data
-- compiles the scala program 
-- runs the program 

run.sh --> #!/bin/bash Script
Orchestrates the entire workflow
-- checks if chamspage_table1.csv exists
    -- if not, runs fet_csv.py to generate it 
-- verifies if CSV was created 
-- checks if Docker image exists 
    -- if not, builds the Docker image
-- Runs the scala analysis inside the Docker container
         
