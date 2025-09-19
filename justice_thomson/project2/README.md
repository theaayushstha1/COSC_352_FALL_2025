# Project2 Docker Usage


## Build the Docker Image

From the project root (where the Dockerfile is located), run:

```bash
docker build -t project2 .
```

This command creates a Docker image named **project2**.

## Run the Script with a URL

To run the script and print results to the screen, pass the target URL as an argument when starting the container:

```bash
docker run --rm project2 <URL>
```

### Example

```bash
docker run project2 https://en.wikipedia.org/wiki/Comparison_of_programming_languages
```

This will execute:

```
python project2.py https://en.wikipedia.org/wiki/Comparison_of_programming_languages
```

inside the container, and you’ll see the script’s output directly in your terminal.



