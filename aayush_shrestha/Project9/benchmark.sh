#!/bin/bash
PDF="Morgan2030.pdf"
QUERY="strategic planning"
N=5
RUNS=5

echo "Extracting passages..."
python3 pdf_extractor.py "$PDF" Morgan2030.json

echo
echo "Scalar (Mojo + pdfsearch_core.py):"
for i in $(seq 1 $RUNS); do
  time python3 -c "from pdfsearch_core import search; search('$PDF', 'Morgan2030.json', '$QUERY', $N)" > /dev/null
done

echo
echo "SIMD (Python + NumPy pdfsearch_simd_core.py):"
for i in $(seq 1 $RUNS); do
  time ./pdfsearch_simd "$PDF" "$QUERY" $N > /dev/null
done
