"""
PDF Search Tool - Mojo Implementation
"""
from sys import argv
from python import Python

fn main() raises:
    var py = Python.import_module("builtins")
    
    # Try using Mojo's argv directly
    var argc = len(argv())
       
    if argc < 4:
        print("Usage: ./pdfsearch <pdf_file> <query> <num_results>")
        print()
        print("Example:")
        print("  ./pdfsearch test_ml.pdf \"machine learning\" 5")
        return
    
    var pdf_path = argv()[1]
    var query = argv()[2]
    var num_results = py.int(argv()[3])
    
    print("=" * 60)
    print("PDF Search Tool - Project 9 (Mojo)")
    print("=" * 60)
    print("Loading PDF:", pdf_path)
    print("Query:", query)
    print("Returning top", num_results, "results")
    print("=" * 60)
    print()
    
    var search_core = Python.import_module("pdfsearch_core")
    _ = search_core.run_search(pdf_path, query, num_results)
