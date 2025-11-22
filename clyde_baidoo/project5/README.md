# project5

The run.sh file contains all the information to build and run the docker image
It also contain flags which triggers how outputs are displayed as shown below;

- ./run.sh (Scrapes web data from the url and displays output to the terminal)

- ./run.sh --output=csv (Scrapes web data and sends output to output.csv)

- ./run.sh --output=json (Scrapes web data into a json file)

**for subsequent extension of this project, I opt to use csv format because;**
- csv format improves readability especially with large data
- csv files can be opened in excel which sends output in tabular form for easy navigation
- csv files are also interoperable with almost every programming language, databases, google sheets, Libre office
- they are also lightweights compared to json files
