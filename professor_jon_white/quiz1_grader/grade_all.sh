#!/bin/bash

# Script to grade all HEIC files in the data directory
# Processes 5 files at a time in parallel
# Usage:
#   ./grade_all.sh                           # Normal grading with image processing
#   ./grade_all.sh --force-run               # Force re-grade with image processing
#   ./grade_all.sh --use-extracted-text      # Fast re-grade using extracted text from JSON
#   ./grade_all.sh --force-run --use-extracted-text  # Combine both flags

# Configuration
DATA_DIR="data"
PDF_OUTPUT_DIR="pdfs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRADE_SCRIPT="$SCRIPT_DIR/grade_quiz.py"
REGRADE_SCRIPT="$SCRIPT_DIR/regrade_quiz.py"
PDF_SCRIPT="$SCRIPT_DIR/create_student_pdf.py"
BATCH_SIZE=5

# Check for --force-run flag
FORCE_RUN=""
if [[ "$*" == *"--force-run"* ]]; then
    FORCE_RUN="--force-run"
    echo "Force run enabled: Will overwrite existing JSON files"
fi

# Check for --use-extracted-text flag
USE_EXTRACTED_TEXT=false
if [[ "$*" == *"--use-extracted-text"* ]]; then
    USE_EXTRACTED_TEXT=true
    echo "Using extracted text mode: Will skip image processing when possible"
fi

if [ -n "$FORCE_RUN" ] || [ "$USE_EXTRACTED_TEXT" = true ]; then
    echo ""
fi

# Check if data directory exists
if [ ! -d "$DATA_DIR" ]; then
    echo "Error: Data directory '$DATA_DIR' not found."
    exit 1
fi

# Create PDF output directory if it doesn't exist
mkdir -p "$PDF_OUTPUT_DIR"

# Check if Python scripts exist
if [ ! -f "$GRADE_SCRIPT" ]; then
    echo "Error: Python script '$GRADE_SCRIPT' not found."
    exit 1
fi

if [ "$USE_EXTRACTED_TEXT" = true ] && [ ! -f "$REGRADE_SCRIPT" ]; then
    echo "Error: Python script '$REGRADE_SCRIPT' not found."
    echo "Need regrade_quiz.py for --use-extracted-text mode."
    exit 1
fi

if [ ! -f "$PDF_SCRIPT" ]; then
    echo "Error: Python script '$PDF_SCRIPT' not found."
    exit 1
fi

# Find all HEIC files
echo "Searching for HEIC files in $DATA_DIR..."
HEIC_FILES=($(find "$DATA_DIR" -type f \( -iname "*.heic" -o -iname "*.HEIC" \)))

if [ ${#HEIC_FILES[@]} -eq 0 ]; then
    echo "No HEIC files found in $DATA_DIR"
    exit 0
fi

echo "Found ${#HEIC_FILES[@]} HEIC files to process"
echo "Processing in batches of $BATCH_SIZE..."
echo ""

# Process files in batches
total_files=${#HEIC_FILES[@]}
processed=0

for ((i=0; i<$total_files; i+=$BATCH_SIZE)); do
    batch_num=$((i / BATCH_SIZE + 1))
    batch_start=$((i + 1))
    batch_end=$((i + BATCH_SIZE < total_files ? i + BATCH_SIZE : total_files))

    echo "========================================"
    echo "Processing Batch $batch_num (files $batch_start-$batch_end of $total_files)"
    echo "========================================"

    # Start up to BATCH_SIZE processes
    pids=()
    for ((j=i; j<i+BATCH_SIZE && j<total_files; j++)); do
        file="${HEIC_FILES[$j]}"
        json_file="${file%.*}.json"

        # Determine which script to use
        if [ "$USE_EXTRACTED_TEXT" = true ] && [ -f "$json_file" ]; then
            # Use regrade script if JSON exists and flag is set
            script_to_use="$REGRADE_SCRIPT"
            input_file="$json_file"
            log_file="${file%.*}_regrade.log"
            echo "Re-grading (text-only): $json_file"
        else
            # Use grade script (with image processing)
            script_to_use="$GRADE_SCRIPT"
            input_file="$file"
            log_file="${file%.*}_grade.log"
            if [ "$USE_EXTRACTED_TEXT" = true ]; then
                echo "Grading (no JSON yet): $file"
            else
                echo "Grading: $file"
            fi
        fi

        # Run Python script in background
        if [ "$script_to_use" = "$REGRADE_SCRIPT" ]; then
            # Regrade script doesn't need --force-run flag (always overwrites)
            python3 "$script_to_use" "$input_file" > "$log_file" 2>&1 &
        else
            # Grade script supports --force-run flag
            python3 "$script_to_use" "$input_file" $FORCE_RUN > "$log_file" 2>&1 &
        fi
        pids+=($!)
    done

    # Wait for all processes in this batch to complete
    echo ""
    echo "Waiting for batch $batch_num to complete..."
    for pid in "${pids[@]}"; do
        wait $pid
    done

    processed=$batch_end
    echo "✓ Batch $batch_num complete ($processed/$total_files files processed)"

    # Generate PDFs for this batch
    echo ""
    echo "Generating PDFs for batch $batch_num..."
    for ((j=i; j<i+BATCH_SIZE && j<total_files; j++)); do
        file="${HEIC_FILES[$j]}"
        json_file="${file%.*}.json"

        if [ -f "$json_file" ]; then
            python3 "$PDF_SCRIPT" "$json_file" "$PDF_OUTPUT_DIR" 2>&1 | grep -E "(Creating|✓|✗)"
        fi
    done
    echo "✓ PDFs generated for batch $batch_num"
    echo ""
done

echo "========================================"
if [ "$USE_EXTRACTED_TEXT" = true ]; then
    echo "All files re-graded!"
    echo "========================================"
    echo "Total files processed: $total_files"
    echo ""
    echo "Results saved as .json files alongside the original HEIC files"
    echo "PDFs saved in $PDF_OUTPUT_DIR/ directory"
    echo "Logs saved as *_grade.log and *_regrade.log files"
else
    echo "All files processed!"
    echo "========================================"
    echo "Total files processed: $total_files"
    echo ""
    echo "Results saved as .json files alongside the original HEIC files"
    echo "PDFs saved in $PDF_OUTPUT_DIR/ directory"
    echo "Logs saved as *_grade.log files"
fi
