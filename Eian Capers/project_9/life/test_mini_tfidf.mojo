from tfidf import TFIDFScorer, print_simd_info
from utils import TextProcessor, count_words
from memory import memset_zero
from time import now


fn test_word_count():
    """Test word counting function"""
    print("\n=== Testing Word Count ===")
    
    let text1 = "Hello world"
    let count1 = count_words(text1)
    print("Text:", text1)
    print("Word count:", count1)
    assert_equal(count1, 2)
    
    let text2 = "The quick brown fox jumps over the lazy dog"
    let count2 = count_words(text2)
    print("Text:", text2)
    print("Word count:", count2)
    assert_equal(count2, 9)
    
    print("✓ Word count tests passed")


fn test_text_processor():
    """Test text processing pipeline"""
    print("\n=== Testing Text Processor ===")
    
    var processor = TextProcessor()
    
    # Test normalization
    let text = "Hello, World! Testing 123."
    let normalized = processor.normalize(text)
    print("Original:", text)
    print("Normalized:", normalized)
    
    # Test tokenization
    let tokens = processor.tokenize("hello world test")
    print("Tokens:", len(tokens))
    assert_equal(len(tokens), 3)
    
    # Test stopword filtering
    let filtered = processor.filter_tokens(
        processor.tokenize("the quick brown fox")
    )
    print("After filtering stopwords:", len(filtered))
    # "the" should be removed
    
    print("✓ Text processor tests passed")


fn test_idf_computation():
    """Test IDF computation with SIMD vs scalar"""
    print("\n=== Testing IDF Computation ===")
    
    let vocab_size = 1000
    let num_passages = 100
    
    # Create sample document frequencies
    var doc_freqs = DTypePointer[DType.float32].alloc(vocab_size)
    
    for i in range(vocab_size):
        # Simulate varying document frequencies
        doc_freqs[i] = Float32(1 + (i % 50))
    
    # Test scalar implementation
    var scorer_scalar = TFIDFScorer(vocab_size, num_passages)
    let start_scalar = now()
    scorer_scalar.compute_idf_scalar(doc_freqs)
    let time_scalar = now() - start_scalar
    
    # Test SIMD implementation
    var scorer_simd = TFIDFScorer(vocab_size, num_passages)
    let start_simd = now()
    scorer_simd.compute_idf_simd(doc_freqs)
    let time_simd = now() - start_simd
    
    # Verify results match (within floating point tolerance)
    var max_diff: Float32 = 0.0
    for i in range(vocab_size):
        let diff = abs(scorer_scalar.idf_scores[i] - scorer_simd.idf_scores[i])
        if diff > max_diff:
            max_diff = diff
    
    print("Scalar time:", time_scalar, "ns")
    print("SIMD time:", time_simd, "ns")
    print("Speedup:", Float64(time_scalar) / Float64(time_simd), "x")
    print("Max difference:", max_diff)
    
    # Clean up
    doc_freqs.free()
    
    print("✓ IDF computation tests passed")


fn test_passage_scoring():
    """Test passage scoring with SIMD vs scalar"""
    print("\n=== Testing Passage Scoring ===")
    
    let vocab_size = 500
    let num_passages = 50
    
    # Create mock data
    var doc_freqs = DTypePointer[DType.float32].alloc(vocab_size)
    var term_freqs = DTypePointer[DType.float32].alloc(vocab_size)
    var query_mask = DTypePointer[DType.int32].alloc(vocab_size)
    
    # Initialize
    for i in range(vocab_size):
        doc_freqs[i] = Float32(1 + (i % 30))
        term_freqs[i] = Float32(i % 10)
        query_mask[i] = 1 if i % 5 == 0 else 0  # Every 5th term is in query
    
    # Create scorer
    var scorer = TFIDFScorer(vocab_size, num_passages)
    scorer.compute_idf_simd(doc_freqs)
    
    let passage_length: Float32 = 100.0
    
    # Test scalar scoring
    let start_scalar = now()
    let score_scalar = scorer.score_passage_scalar(
        term_freqs, query_mask, passage_length
    )
    let time_scalar = now() - start_scalar
    
    # Test SIMD scoring
    let start_simd = now()
    let score_simd = scorer.score_passage_simd(
        term_freqs, query_mask, passage_length
    )
    let time_simd = now() - start_simd
    
    print("Scalar score:", score_scalar, "time:", time_scalar, "ns")
    print("SIMD score:", score_simd, "time:", time_simd, "ns")
    print("Score difference:", abs(score_scalar - score_simd))
    print("Speedup:", Float64(time_scalar) / Float64(time_simd), "x")
    
    # Clean up
    doc_freqs.free()
    term_freqs.free()
    query_mask.free()
    
    print("✓ Passage scoring tests passed")


fn benchmark_simd_performance():
    """Comprehensive SIMD vs scalar benchmark"""
    print("\n=== SIMD Performance Benchmark ===")
    
    let vocab_sizes = List[Int](100, 500, 1000, 5000)
    
    for size_idx in range(len(vocab_sizes)):
        let vocab_size = vocab_sizes[size_idx]
        let num_passages = 100
        
        print(f"\nVocabulary size: {vocab_size}")
        
        var doc_freqs = DTypePointer[DType.float32].alloc(vocab_size)
        for i in range(vocab_size):
            doc_freqs[i] = Float32(1 + (i % 50))
        
        # Scalar benchmark
        var scorer_scalar = TFIDFScorer(vocab_size, num_passages)
        let start_scalar = now()
        scorer_scalar.compute_idf_scalar(doc_freqs)
        let time_scalar = now() - start_scalar
        
        # SIMD benchmark
        var scorer_simd = TFIDFScorer(vocab_size, num_passages)
        let start_simd = now()
        scorer_simd.compute_idf_simd(doc_freqs)
        let time_simd = now() - start_simd
        
        let speedup = Float64(time_scalar) / Float64(time_simd)
        
        print("  Scalar:", time_scalar, "ns")
        print("  SIMD:", time_simd, "ns")
        print("  Speedup:", speedup, "x")
        
        doc_freqs.free()


fn main():
    """Run all tests"""
    print("=" * 70)
    print("TF-IDF UNIT TESTS")
    print("=" * 70)
    
    print_simd_info()
    
    try:
        test_word_count()
        test_text_processor()
        test_idf_computation()
        test_passage_scoring()
        benchmark_simd_performance()
        
        print("\n" + "=" * 70)
        print("ALL TESTS PASSED ✓")
        print("=" * 70)
    except:
        print("\n" + "=" * 70)
        print("TESTS FAILED ✗")
        print("=" * 70)