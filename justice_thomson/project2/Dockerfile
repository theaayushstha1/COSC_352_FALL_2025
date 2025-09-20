# Use standard Python image
<<<<<<< HEAD
FROM python:3.9
=======
FROM python:3.9-slim

>>>>>>> b9705eb308ec163c8afb5068f9df9eac424a5f17

# Set working directory
WORKDIR /app

<<<<<<< HEAD
# Copy the Python script
COPY project2.py .

# Run the Python script
CMD ["python", "project2.py"]
=======

# Copy the Python script
COPY project2.py .


# Default: run the script, but let you pass arguments
ENTRYPOINT ["python", "project2.py"]
# Run code as docker run <image name> <url with table to extract>
>>>>>>> b9705eb308ec163c8afb5068f9df9eac424a5f17
