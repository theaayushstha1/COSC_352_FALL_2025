This project demonstarates the use of a Docker container to run the Python script from Project1.

### How to Build the Docker Image

1.  Ensure you have Docker installed (or are using Codespaces).
2.  Navigate to the `project2` directory in your terminal.
3.  Run the following command to build the Docker image:
    ```bash
    docker build -t your_username_project2 .
    ```
    (Replace `your_username` with your actual username.)

### How to Run the Docker Container

1.  After the image is successfully built, run the container with the following command:
    ```bash
    docker run your_username_project2
    ```
2.  The output of `test.py` should be displayed in the terminal.