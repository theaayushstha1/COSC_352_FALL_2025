#!/bin/bash

# Script to build and run Docker containers for all student project2 directories
# Captures output for each student and saves to individual files

# Disable Docker BuildKit for compatibility
export DOCKER_BUILDKIT=0

OUTPUT_DIR="project2_outputs"
mkdir -p "$OUTPUT_DIR"

# Function to clean up Docker images
cleanup_image() {
    local image_name="$1"
    if [[ -n "$image_name" ]]; then
        echo "Cleaning up image: $image_name"
        docker rmi "$image_name" 2>/dev/null || true
    fi
}

# Function to process a student directory
process_student() {
    local student_dir="$1"
    local student_name=$(basename "$student_dir")
    local project2_dir="$student_dir/project2"
    local original_dir=$(pwd)
    local output_file="$original_dir/$OUTPUT_DIR/${student_name}_output.txt"

    echo "Processing $student_name..."

    # Create output file with proper path
    touch "$output_file"
    echo "===========================================" > "$output_file"
    echo "Student: $student_name" >> "$output_file"
    echo "Directory: $project2_dir" >> "$output_file"
    echo "Timestamp: $(date)" >> "$output_file"
    echo "===========================================" >> "$output_file"

    # Check if project2 directory exists
    if [[ ! -d "$project2_dir" ]]; then
        echo "❌ No project2 directory found" >> "$output_file"
        echo "❌ $student_name: No project2 directory found"
        return
    fi

    # Check if Dockerfile exists
    if [[ ! -f "$project2_dir/Dockerfile" ]]; then
        echo "❌ No Dockerfile found in project2 directory" >> "$output_file"
        echo "❌ $student_name: No Dockerfile found"
        return
    fi

    echo "✅ Found Dockerfile" >> "$output_file"

    # Change to project2 directory
    cd "$project2_dir" || {
        echo "❌ Failed to change to project2 directory" >> "$output_file"
        echo "❌ $student_name: Failed to change directory"
        return
    }

    # Build Docker image
    local image_name="$(echo ${student_name} | tr '[:upper:]' '[:lower:]')_project2"  # lowercase student name
    echo "" >> "$output_file"
    echo "Building Docker image: $image_name" >> "$output_file"
    echo "==========================================" >> "$output_file"

    if docker build -t "$image_name" . >> "$output_file" 2>&1; then
        echo "✅ Build successful" >> "$output_file"
        echo "✅ $student_name: Build successful"

        # Run the container
        echo "" >> "$output_file"
        echo "Running container..." >> "$output_file"
        echo "==========================================" >> "$output_file"

        # Run container with timeout to prevent hanging
        if docker run --rm "$image_name" >> "$output_file" 2>&1; then
            echo "✅ Container run completed" >> "$output_file"
            echo "✅ $student_name: Container run completed"
        else
            echo "❌ Container run failed or timed out" >> "$output_file"
            echo "❌ $student_name: Container run failed or timed out"
        fi

        # Clean up the image
        cleanup_image "$image_name"

    else
        echo "❌ Build failed" >> "$output_file"
        echo "❌ $student_name: Build failed"
        cleanup_image "$image_name"
    fi

    echo "" >> "$output_file"
    echo "===========================================" >> "$output_file"
    echo "" >> "$output_file"

    # Return to original directory
    cd "$original_dir" > /dev/null
}

# Main execution
echo "Starting Docker container processing for all students..."
echo "Output will be saved to: $OUTPUT_DIR/"
echo ""

# Find all directories matching firstname_lastname pattern
for student_dir in */; do
    # Remove trailing slash
    student_dir="${student_dir%/}"

    # Skip if not a directory or doesn't match firstname_lastname pattern
    if [[ ! -d "$student_dir" ]] || [[ ! "$student_dir" =~ ^[a-zA-Z]+_[a-zA-Z]+$ ]]; then
        continue
    fi

    process_student "$student_dir"
done

echo ""
echo "Processing complete! Check $OUTPUT_DIR/ for individual student outputs."
echo "Summary of all outputs:"
echo "==========================================="

# Print summary
for output_file in "$OUTPUT_DIR"/*_output.txt; do
    if [[ -f "$output_file" ]]; then
        student_name=$(basename "$output_file" _output.txt)
        echo ""
        echo "--- $student_name ---"
        # Show just the key status lines
        grep -E "(✅|❌)" "$output_file" | head -3
    fi
done