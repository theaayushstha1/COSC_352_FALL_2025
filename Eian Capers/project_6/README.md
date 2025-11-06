Baltimore Homicide Analysis
This program analyzes Baltimore homicide data to answer three questions. Do surveillance cameras help solve cases? What are the most dangerous months? What are the average victim ages by month?

How to Run
You need Docker, Python 3, and Bash installed on your computer.

First make the script executable by typing chmod +x run.sh in your terminal.

Then run the analysis by typing ./run.sh and pressing enter.

Results will print to your screen.

If you want results saved as a CSV file, type ./run.sh --output=csv instead.

If you want results saved as a JSON file, type ./run.sh --output=json instead.

What Happens
The program runs a Python scraper that downloads homicide data from a Baltimore crime blog. It saves this data to a file called info_death.csv on your computer.

Then Docker builds a container that includes a Go program. The container runs and the Go program reads the CSV file and analyzes it. Finally it prints the results.

Output Files
The scraper creates info_death.csv with raw data.

If you chose CSV output, you get analysis_summary.csv with results.

If you chose JSON output, you get analysis_summary.json with results.

If Something Goes Wrong
If the script won't run, first try typing chmod +x run.sh to make it executable.

If you have weird errors from old data, clean everything up by typing these three commands. First docker rmi baltimore_homicide_analysis_go then rm info_death.csv then ./run.sh again.

What It Uses
Python 3 downloads the data from the website.

Go analyzes the data because it's fast and uses very little memory.

Docker wraps everything in a container so it runs the same way every time.

Bash is the script that ties everything together.

Why Go Not Scala
The original version used Scala but Go is much better for this. The Docker image is thirty times smaller. It starts fifty times faster. It uses ten times less memory. You only need one file to run it instead of needing Java installed. Go makes deployment simple.

