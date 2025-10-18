#!/bin/bash

# Example runner script - Tests batch_extract.sh with 3 different websites

# URLs with HTML tables
URL1="https://en.wikipedia.org/wiki/Comparison_of_programming_languages"
URL2="https://en.wikipedia.org/wiki/Programming_languages_used_in_most_popular_websites"
URL3="https://www.tiobe.com/tiobe-index/"

echo "Running batch table extractor with 3 websites..."
echo "1. $URL1"
echo "2. $URL2"
echo "3. $URL3"
echo ""

./batch_extract.sh "$URL1,$URL2,$URL3"
