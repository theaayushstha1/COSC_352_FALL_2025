#!/bin/bash

# grab the first argument (comma-separated urls)
urls=$1

# error check: make sure the user provided urls
if [ -z "$urls" ]; then
    echo "Usage: $0 url1,url2,url3"
    exit 1
fi

# define output directory inside project3
output_dir="Judah_whiddon/project3/output_csvs"

# uncomment the following line if you want a clean run (delete old results)
# rm -rf $output_dir

# create the output folder if it doesn't exist
mkdir -p $output_dir

# build the docker image from project2
docker build -t project2_image ../project2

# loop through each url provided
for url in $(echo $urls | tr "," "\n")
do
    echo "Processing $url ..."

    # make a safe filename from the url
    filename=$(echo $url | sed 's|https\?://||' | sed 's|/|_|g')

    # run the docker container: scraper takes url + output file
    docker run --rm -v $(pwd)/$output_dir:/app/output project2_image \
        "$url" "/app/output/${filename}.csv"
done

# zip the directory of results
zip -r ${output_dir}.zip $output_dir

# final confirmation
echo "Done! All CSVs are in ${output_dir}.zip"
