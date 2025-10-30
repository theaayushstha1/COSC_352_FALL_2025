# 1. Start with an official Python image
FROM python:3.10

# 2. Set a working directory inside the container
WORKDIR /app

# 3. Copy dependency list first (so Docker caches dependencies)
#COPY requirements.txt .
#3. copy comparison file first
#COPY Comparison_of_programming_languages.html /app/
# 4. Install dependencies
#RUN pip install -r requirements.txt

# 5. Copy the rest of your project files
COPY . .

# 6. Command to run your Python program
CMD ["python", "html_table_to_csv.py"]
