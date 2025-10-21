# PROJECT 3 - Bash Scripts

This project focuses on coding a Bash script that takes in a list of webpages, reads the HTML tables and outputs a CSV file of each table by calling a Docker container.

## Usage


```bash
chmod +x table_bash.sh
docker build -t html_table_parser .
./table_bash.sh https://github.com/quambene/pl-comparison,https://www.tiobe.com/tiobe-index/,https://en.wikipedia.org/wiki/Comparison_of_programming_languages

