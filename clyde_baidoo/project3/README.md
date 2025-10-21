#project3 

1. Run ./webpage_to_csv.sh "https://pypl.github.io/PYPL.html,https://github.com/quambene/pl-comparison,https://www.reddit.com/r/rust/comments/uq6j2q/programming_language_comparison_cheat_sheet/"

2. In case you run into permission errors, do;
    - if webpage_to_csv_outputs was not created successfully, mkdir webpage_to_csv_outputs
    - chmod 777 webpage_to_csv_ouptuts
    - run the script again.

3. all the csv files are saved in the webpage_to_csv_outputs directory
4. webpage_to_csv_output.zip is also created