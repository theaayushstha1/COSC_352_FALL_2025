#!/bin/bash
echo "===============================" 
echo "Project 4 Script" 
echo "==============================="

IMAGE_NAME="baltimore_homicide_analysis"
CSV_FILE="chamspage_table1.csv"

if [ ! -f $CSV_FILE ]; then
    echo "Fetching data from website to generate CSV file ... "
    python3 fetch_csv.py 
fi 

if [ ! -f $CSV_FILE ]; then
    echo " Error: CSV file was NOT created!" 
    exit 1 
fi 

echo "✅ CSV file exists!" 

if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    echo "Building Docker image ..." 
    docker build -t "$IMAGE_NAME" . 
fi 

echo "Running Scala analysis in Docker" 
docker run --rm "$IMAGE_NAME"

echo "DONE!" 