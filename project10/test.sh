#!/bin/bash
# Test script for Turing Machine Simulator

echo "================================"
echo "Testing Turing Machine Simulator"
echo "================================"
echo ""

echo "1. Testing Binary Palindrome TM with CLI..."
echo "   Testing '101' (should accept)..."
python3 cli.py -m palindrome -i "101" -q
if [ $? -eq 0 ]; then
    echo "   ✓ PASSED"
else
    echo "   ✗ FAILED"
fi

echo "   Testing '110' (should reject)..."
python3 cli.py -m palindrome -i "110" -q
if [ $? -eq 1 ]; then
    echo "   ✓ PASSED"
else
    echo "   ✗ FAILED"
fi

echo ""
echo "2. Testing Batch Mode..."
python3 cli.py -m palindrome -b "101" "1001" "110"

echo ""
echo "3. Testing Balanced Parentheses TM..."
python3 cli.py -m parentheses -i "(())" -q
if [ $? -eq 0 ]; then
    echo "   ✓ PASSED"
else
    echo "   ✗ FAILED"
fi

echo ""
echo "4. Testing Core TM Module..."
python3 turing_machine.py > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✓ Core module works"
else
    echo "   ✗ Core module has errors"
fi

echo ""
echo "================================"
echo "All tests completed!"
echo "================================"
