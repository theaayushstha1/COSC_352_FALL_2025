#!/usr/bin/env python3
import sys
import time
from pdfsearch_enhanced import TFIDFSearchEngine

def benchmark_search(pdf_path, queries, top_n=5):
    """Benchmark search performance"""
    print("="*60)
    print("PDF SEARCH BENCHMARK")
    print("="*60)
    
    # Load document once
    engine = TFIDFSearchEngine()
    
    print(f"\nLoading: {pdf_path}")
    start = time.time()
    pages = engine.extract_text_from_pdf(pdf_path)
    passages = engine.create_passages(pages)
    engine.build_index(passages)
    load_time = time.time() - start
    
    print(f"✓ Loaded {len(pages)} pages, {len(passages)} passages")
    print(f"✓ Load time: {load_time:.3f}s")
    print(f"✓ Index size: {len(engine.doc_freq)} unique terms\n")
    
    # Benchmark each query
    results = []
    for i, query in enumerate(queries, 1):
        print(f"Query {i}: \"{query}\"")
        
        start = time.time()
        search_results = engine.search(query, top_n)
        search_time = time.time() - start
        
        print(f"  ⏱  Search time: {search_time*1000:.2f}ms")
        print(f"  📊 Results: {len(search_results)}")
        if search_results:
            print(f"  🎯 Top score: {search_results[0]['score']:.2f}")
        print()
        
        results.append({
            'query': query,
            'time_ms': search_time * 1000,
            'results': len(search_results)
        })
    
    # Summary
    print("="*60)
    print("SUMMARY")
    print("="*60)
    total_time = sum(r['time_ms'] for r in results)
    avg_time = total_time / len(results)
    
    print(f"Total queries: {len(queries)}")
    print(f"Total search time: {total_time:.2f}ms")
    print(f"Average time per query: {avg_time:.2f}ms")
    print(f"Passages per second: {len(passages) * len(queries) / (total_time/1000):.0f}")
    print()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 benchmark.py <pdf_file>")
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    
    # Test queries
    test_queries = [
        "research university",
        "strategic goals",
        "student success",
        "faculty development",
        "community engagement"
    ]
    
    benchmark_search(pdf_path, test_queries, top_n=5)
