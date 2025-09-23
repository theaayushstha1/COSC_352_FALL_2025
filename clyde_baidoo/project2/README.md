# project2

*This is a brief instructional documentation to running a dockerized container for project 1*

- Create a file called "Dockerfile" to handle your docker instructions
- Create a docker file ".dockerignore" to skip unwanted files/directories in your container
- Create a file "compose.yaml" to specify server instructions
- Create a ".gitignore" file and include envs and packaging distributions
- From project 1, run pip freeze > requirements.txt to package all dependencies into the text file and move it into the parent directory, eg. clyde_baidoo


*Building and running the docker container*

- In the parent directory (clyde_baidoo);
- run (docker build -f project2/Dockerfile -t webpage-to-csv-app .) to build the container //ignore parenthesis
- docker images - to verify your successful image built
- run (docker run -w /tmp webpage-to-csv-app python /app/webpage_to_csv.py url) eg. (docker run -w /tmp webpage-to-csv-app python /app/webpage_to_csv.py https://en.wikipedia.org/wiki/Comparison_of_programming_languages)
