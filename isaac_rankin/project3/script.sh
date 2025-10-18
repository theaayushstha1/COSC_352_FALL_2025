#!/bin/bash

docker build . --tag read_html

data=$1

websites=$( echo $data | tr ',' '\n') 

for site in $websites
do
    echo "Reading $site..."
    docker run \
        -v $(pwd)/csv:/app/csv \
        read_html \
        python read_html_table.py "$site"
    echo ""
done

zip -r csv.zip csv/

echo ""
echo "Zipped all CSVs into csv.zip"
