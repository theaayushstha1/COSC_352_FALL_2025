#!/bin/bash

echo "=========================================="
echo "PDF Search Performance Benchmark"
echo "=========================================="
echo ""

echo "Running SCALAR version (baseline)..."
time ./pdfsearch test_ml.pdf "gradient descent" 3 > /dev/null 2>&1
echo ""

echo "Running SIMD version (optimized)..."
time ./pdfsearch_simd test_ml.pdf "gradient descent" 3 > /dev/null 2>&1
echo ""

echo "=========================================="
echo "Testing with larger document..."
echo "=========================================="
echo ""

echo "Running SCALAR version on Morgan 2030..."
time ./pdfsearch Morgan_2030.pdf "sustainability" 5 > /dev/null 2>&1
echo ""

echo "Running SIMD version on Morgan 2030..."
time ./pdfsearch_simd Morgan_2030.pdf "sustainability" 5 > /dev/null 2>&1
echo ""

echo "Benchmark complete!"
