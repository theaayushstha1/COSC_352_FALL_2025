#!/bin/bash

#Bash Script to process ultiple websites using a Docker


#Check if the urls were provided
if [ $# -eq 0 ]; then
    echo "Usuage: $0 'url1,url2,url3'"
    echo "Example: $0 'https://reddit.com'"
    exit 1
fi

#Check if the docker image exists, if not then build one
echo "Checking for Docker image"
if ! docker images | grep -q "table2csv"; then
    echo "Docker image 'table2csv' not found. Creating one for you"
    docker build -t table2csv . 
    if [ $? -ne 0 ]; then
        echo "Error: Could not build docker image"
        exit 1
    fi
    echo "Docker has been created!"
else
    echo "Docker image 'table2csv' found."
fi


#Create directory for output
output="scraped_tables"
mkdir -p "output"
echo "Output Directory: $output"


#Seperate the urls by comma
IFS-',' read -ra URLS <<< "$1"


echo "Processing ${#URLS[@]} websites"

#Process the urls
for url in "${URLS[@]}"; do
    url=$(echo "$url" | xrags)

    echo "----------------"
    echo "Processing: $url"

    #Copy website name from url
    website_name=$(echo "url" | sed -E 's|https?://([^/]+).*|\1|' | tr '.' '_' | tr '/' '_')
    

    #Create temp dir for the website
    temp="${output}/temp_${website_name}"
    mkdir -p "$temp"


    #Run the docker container
    echo "Running Docker Container for $website_name"
    docker run --rm -v "$(pwd)/${temp}:/app/output" table2csv


    #Check if Docker run was successful
    if [ $? -ne 0 ]; then
        echo "Error: failed to process $url"
        rmdir "$temp" 2>/dev/null
        continue
    fi


    #Rename files with website prefix
    echo "Remaining files with prefix: ${website_name}_"
    file_count=0
    for file in "$temp"/table_*.csv; do
        if [ -f "$file" ]; then 
            filename=$(basename "$file")
            new_name="${website_name}_${filename}"
            mv "$file" "${output}/${new_name}"
            file_count=$((file_count + 1))
        fi
    done

    redir "$temp" 2>/dev/null

    echo "Extracted $file_count table(s) from $website_name"
done

echo "----------------"


#Count total csv files
total_files=$(find "$output" -name "*.csv" -type f | wc -l)
echo "Total CSV files created: $total_files"


#Create Zip File
if [ $total_files -gt 0 ]; then
    ZIP_NAME="scraped_tables_$(date ++%Y%m%d_%H%M%S).zip"
    echo "Creating zip file: $ZIP_NAME"
    zip -r "ZIP_NAME" "OUTPUT_DIR"

    if [ $? -eq 0 ]; then
        echo "Success, Zip File created: $ZIP_NAME"
        echo "Files are also available in directory: $output"
    else
        echo "Error: Failed to create zip file"
        exit 1
    fi
else
    echo "Warning: No csv files were created"
    exit 1
fi

echo "----------------"
echo "Processing Complete"