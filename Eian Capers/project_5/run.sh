echo "===============================" 
echo "Project 5 Script" 
echo "==============================="

IMAGE_NAME="baltimore_homicide_analysis"
CSV_FILE="info_death.csv"
OUTPUT_FLAG=""

# Parse command line arguments for output flag
for arg in "$@"; do
    case $arg in
        --output=*)
            OUTPUT_FLAG="$arg"
            ;;
    esac
done

# Fetch data if CSV doesn't exist
if [ ! -f "$CSV_FILE" ]; then
    echo "Fetching data from website to generate CSV file ... "
    python3 get_mine.py 
fi 

if [ ! -f "$CSV_FILE" ]; then
    echo "Error: CSV file was NOT created!" 
    exit 1 
fi 

echo "✅ CSV file exists!" 

# Build docker image if it doesn't exist
if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    echo "Building Docker image ..." 
    docker build -t "$IMAGE_NAME" . 
fi 

echo "Running Scala analysis in Docker" 

# Mount current directory and pass arguments to Scala program
if [ -z "$OUTPUT_FLAG" ]; then
    echo "Output format: stdout (default)"
    docker run --rm \
        -v "$(pwd)":/app \
        -w /app \
        "$IMAGE_NAME"
else
    echo "Output format: ${OUTPUT_FLAG#*=}"
    docker run --rm \
        -v "$(pwd)":/app \
        -w /app \
        "$IMAGE_NAME" \
        "$OUTPUT_FLAG"
fi

echo ""
echo "DONE!" 