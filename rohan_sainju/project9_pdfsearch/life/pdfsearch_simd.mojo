"""
PDF Search Tool - SIMD Optimized Version
Demonstrates SIMD for text processing
"""
from sys import argv
from python import Python

fn main() raises:
    var py = Python.import_module("builtins")
    var time = Python.import_module("time")
    
    var argc = len(argv())
    
    if argc < 4:
        print("Usage: ./pdfsearch_simd <pdf_file> <query> <num_results>")
        return
    
    var pdf_path = argv()[1]
    var query = argv()[2]
    var num_results = py.int(argv()[3])
    
    print("=" * 60)
    print("PDF Search Tool - Project 9 (SIMD Optimized)")
    print("=" * 60)
    print("Loading PDF:", pdf_path)
    print("Query:", query)
    print("Returning top", num_results, "results")
    print("=" * 60)
    print()
    
    # Benchmark: Time the search
    var start_time = time.time()
    
    # Use SIMD-optimized Python core
    var search_core = Python.import_module("pdfsearch_simd_core")
    _ = search_core.run_search(pdf_path, query, num_results)
    
    var end_time = time.time()
    var elapsed = py.float(end_time) - py.float(start_time)
    
    print()
    print("Performance:")
    print("  Total time:", elapsed, "seconds")
