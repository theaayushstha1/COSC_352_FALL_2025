Baltimore Homicide Data Analysis
This project analyzes Baltimore homicide data to determine if surveillance cameras affect case closure rates and identify the most dangerous months with average victim ages.
Requirements
You need Docker, Python 3, and Bash installed on your system.
How to Run
First make the script executable by running chmod +x run.sh
Then run the script with ./run.sh for terminal output, or use ./run.sh --output=csv for CSV format, or ./run.sh --output=json for JSON format.
What Happens
The script scrapes homicide data from chamspage.blogspot.com, builds a Docker container with Scala, and analyzes the data to produce results.
Output Files
The program creates info_death.csv with raw data. If you choose CSV output it creates analysis_summary.csv. If you choose JSON output it creates analysis_summary.json.
Troubleshooting
To rebuild everything, remove the Docker image with docker rmi baltimore_homicide_analysis, delete info_death.csv, then run ./run.sh again.
If you get a permission error, run chmod +x run.sh first.
Technology
Built with Scala 2.13.12, OpenJDK 11, Docker, and Python 3.