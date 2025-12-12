#!/bin/bash

# Comprehensive Test Script for Turing Machine Simulator
# This script tests all complexity levels with various inputs

echo "=================================="
echo "Turing Machine Simulator - Test Suite"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testing EASY Complexity - Equal 0s and 1s${NC}"
echo "=================================================="

echo "Test 1: Input '01' (should PASS)"
docker run turing-machine python cli.py --complexity easy --input "01"
echo ""

echo "Test 2: Input '0011' (should PASS)"
docker run turing-machine python cli.py --complexity easy --input "0011"
echo ""

echo "Test 3: Input '0' (should FAIL)"
docker run turing-machine python cli.py --complexity easy --input "0"
echo ""

echo "Test 4: Input '001' (should FAIL)"
docker run turing-machine python cli.py --complexity easy --input "001"
echo ""

echo -e "${YELLOW}Testing MEDIUM Complexity - Binary Palindrome${NC}"
echo "=================================================="

echo "Test 5: Input '101' (should PASS)"
docker run turing-machine python cli.py --complexity medium --input "101"
echo ""

echo "Test 6: Input '1001' (should PASS)"
docker run turing-machine python cli.py --complexity medium --input "1001"
echo ""

echo "Test 7: Input '10' (should FAIL)"
docker run turing-machine python cli.py --complexity medium --input "10"
echo ""

echo "Test 8: Input '110' (should FAIL)"
docker run turing-machine python cli.py --complexity medium --input "110"
echo ""

echo -e "${YELLOW}Testing HARD Complexity - Balanced Parentheses${NC}"
echo "=================================================="

echo "Test 9: Input '()' (should PASS)"
docker run turing-machine python cli.py --complexity hard --input "()"
echo ""

echo "Test 10: Input '(())' (should PASS)"
docker run turing-machine python cli.py --complexity hard --input "(())"
echo ""

echo "Test 11: Input '(' (should FAIL)"
docker run turing-machine python cli.py --complexity hard --input "("
echo ""

echo "Test 12: Input ')(' (should FAIL)"
docker run turing-machine python cli.py --complexity hard --input ")("
echo ""

echo "=================================="
echo -e "${GREEN}All tests completed!${NC}"
echo "=================================="
echo ""
echo "To run the web interface:"
echo "  docker run -p 5000:5000 turing-machine"
echo "  Then visit: http://localhost:5000"
echo ""