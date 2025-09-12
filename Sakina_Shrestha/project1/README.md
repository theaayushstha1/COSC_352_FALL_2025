# HTML Table to CSV Extractor


How to Run


Open a terminal in your folder (or use GitHub Codespaces).



Type one of these commands:





For a webpage:

python read_html_table.py https://en.wikipedia.org/wiki/Comparison_of_programming_languages



For a local HTML file:

python read_html_table.py myfile.html



To name files differently (e.g., output_1.csv):

python read_html_table.py https://en.wikipedia.org/wiki/Comparison_of_programming_languages output

What we get





Five CSV files: table_1.csv, table_2.csv, table_3.csv, table_4.csv, table_5.csv.



Each file has a table from the webpage, with rows and columns ready for spreadsheets.



Example output in terminal:

Saved table_1.csv (140 rows)
Saved table_2.csv (8 rows)
Saved table_3.csv (X rows)
Saved table_4.csv (Y rows)
Saved table_5.csv (Z rows)
Extracted 5 tables from https://en.wikipedia.org/wiki/Comparison_of_programming_languages (limited to 5 for project)

Requirements





Python 3 (comes with GitHub Codespaces or your computer).



No extra Python packages needed.



GitHub to store the code (use Codespaces  on Windows).

