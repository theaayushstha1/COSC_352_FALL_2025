#!/bin/bash

# Script to build and run all project4 Docker containers
# Collects output from each student's project4 and saves to a consolidated file

set -e

# Output file
OUTPUT_FILE="professor_jon_white/all_project4_output.txt"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$REPO_ROOT"

# Clear or create output file
> "$OUTPUT_FILE"

echo "======================================"
echo "Building and Running All Project 4s"
echo "======================================"
echo ""

# Function to build and run a project4
build_and_run_project4() {
    local project_path=$1
    local student_name=$2

    echo "Processing: $student_name"
    echo "Path: $project_path"

    # Add header to output file
    {
        echo ""
        echo "=========================================="
        echo "STUDENT: $student_name"
        echo "PATH: $project_path"
        echo "=========================================="
        echo ""
    } >> "$OUTPUT_FILE"

    # Check if Dockerfile exists
    if [ ! -f "$project_path/Dockerfile" ]; then
        echo "  WARNING: No Dockerfile found, skipping..."
        echo "ERROR: No Dockerfile found" >> "$OUTPUT_FILE"
        echo ""
        return
    fi

    # Build Docker image
    local image_name="project4_${student_name}"
    image_name=$(echo "$image_name" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_-')

    echo "  Building Docker image: $image_name"

    if docker build -t "$image_name" "$project_path" > /dev/null 2>&1; then
        echo "  Build successful"
    else
        echo "  Build failed"
        echo "ERROR: Build failed" >> "$OUTPUT_FILE"
        return
    fi

    # Run Docker container
    echo "  Running container..."

    if timeout 60s docker run --rm "$image_name" >> "$OUTPUT_FILE" 2>&1; then
        echo "  Run successful"
        echo "" >> "$OUTPUT_FILE"
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo "  Run timed out (60s limit)"
            echo "(TIMED OUT - 60 seconds)" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        else
            echo "  Run failed"
            echo "(RUN FAILED)" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        fi
    fi

    echo ""
}

# Find all project4 directories (case-insensitive)
project4_dirs=()

# Find lowercase project4
while IFS= read -r dir; do
    project4_dirs+=("$dir")
done < <(find . -type d -name "project4" -not -path "*/\.*" | sort)

# Find uppercase Project4
while IFS= read -r dir; do
    project4_dirs+=("$dir")
done < <(find . -type d -name "Project4" -not -path "*/\.*" | sort)

# Process each project4 directory
for project_dir in "${project4_dirs[@]}"; do
    # Remove leading ./
    project_dir="${project_dir#./}"

    # Extract student name from path
    student_name=$(echo "$project_dir" | cut -d'/' -f1)

    # Skip if it's just "project4" at root level
    if [ "$project_dir" = "project4" ] || [ "$project_dir" = "Project4" ]; then
        student_name="root_level"
    fi

    build_and_run_project4 "$project_dir" "$student_name"
done

echo "======================================"
echo "All projects processed!"
echo "======================================"
echo ""
echo "Output saved to: $OUTPUT_FILE"
echo ""
echo "Summary:"
echo "--------"
total_projects=${#project4_dirs[@]}
echo "Total projects found: $total_projects"
echo ""

# Show summary of results
{
    echo ""
    echo "=========================================="
    echo "SUMMARY"
    echo "=========================================="
    echo "Total projects processed: $total_projects"
    echo "Completion time: $(date)"
    echo ""
} >> "$OUTPUT_FILE"

echo "View results with: cat $OUTPUT_FILE"
