#!/bin/bash

# Test script for Turing Machine
echo "Building Docker image..."
docker build -t turing-machine .

echo ""
echo "Running test cases..."
echo "===================="

test_cases=("01" "10" "0011" "1100" "0110" "000" "111" "0" "1" "001")

for test in "${test_cases[@]}"
do
    echo ""
    echo "Testing input: $test"
    echo "$test" | docker run -i turing-machine
    echo "---"
done