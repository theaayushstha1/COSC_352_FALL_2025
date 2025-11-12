This project analyzes Baltimore homicide data to answer two important questions:
Question 1: Do Surveillance Cameras Help Solve Cases?
The code calculates what percentage of homicide cases get solved when there's a surveillance camera present versus when there isn't one. This helps us understand if cameras make a difference in closing cases.
Question 2: When Are The Most Dangerous Months?
The code looks at all homicides by month to find out which months have the most incidents. It also calculates the average age of victims in each month.
How It Works

Python Scraper (get_mine.py)

Visits a website that tracks Baltimore homicides
Extracts data from HTML tables
Saves everything into a CSV file called info_death.csv


Scala Analyzer (The_article.scala)

Reads the CSV file
Counts cases with/without cameras and calculates closure rates
Groups homicides by month and calculates statistics
Prints nice formatted results to the screen


Docker Container (Dockerfile)

Packages everything into a container
Installs Scala and Python
Compiles and runs the analysis automatically