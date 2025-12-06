from python import Python
from sys import argv

fn main() raises:
    print()
    print("╔" + "="*78 + "╗")
    print("║" + " "*20 + "MOJO PDF SEARCH ENGINE" + " "*36 + "║")
    print("╚" + "="*78 + "╝")
    print()
    
    var args = argv()
    
    if len(args) < 4:
        print("Usage: mojo pdfsearch.mojo <pdf_file> <query> <top_n>")
        print()
        print("Example:")
        print('  mojo pdfsearch.mojo document.pdf "gradient descent optimization" 3')
        return
    
    var pdf_path = args[1]
    var query = args[2]
    var top_n = atol(args[3])
    
    # Import modules
    var pypdf2 = Python.import_module("PyPDF2")
    var re = Python.import_module("re")
    var math = Python.import_module("math")
    var builtins = Python.import_module("builtins")
    
    print("=" * 80)
    print("Extracting text from PDF:", pdf_path)
    print("=" * 80)
    
    # Extract text from PDF
    var pdf_file = builtins.open(pdf_path, 'rb')
    var pdf_reader = pypdf2.PdfReader(pdf_file)
    var num_pages = builtins.len(pdf_reader.pages)
    
    print("Total pages:", num_pages)
    
    var passages = Python.evaluate("[]")
    
    for i in range(num_pages):
        var page = pdf_reader.pages[i]
        var text = page.extract_text()
        var parts = text.split("\n\n")
        
        for part in parts:
            var para = part.strip()
            if builtins.len(para) > 50:
                var p = Python.evaluate("{'text': '', 'page': 0, 'score': 0.0}")
                p["text"] = para
                p["page"] = i + 1
                passages.append(p)
    
    pdf_file.close()
    
    var total_passages = builtins.len(passages)
    print("Extracted", total_passages, "passages")
    print()
    
    print("=" * 80)
    print('Results for: "' + query + '"')
    print("=" * 80)
    
    # Tokenize query
    var query_lower = query.lower()
    var query_terms = re.findall(r'\b\w{3,}\b', query_lower)
    
    if builtins.len(query_terms) == 0:
        print("Error: No valid query terms")
        return
    
    print("Query terms:", query_terms)
    print()
    
    # Build document frequency
    var term_doc_freq = Python.evaluate("{}")
    
    for term in query_terms:
        var doc_count = 0
        for passage in passages:
            var text_lower = passage["text"].lower()
            if term in text_lower:
                doc_count += 1
        term_doc_freq[term] = doc_count
    
    # Compute TF-IDF scores
    for passage in passages:
        var text_lower = passage["text"].lower()
        var tokens = re.findall(r'\b\w{3,}\b', text_lower)
        var passage_length = builtins.float(builtins.len(tokens))
        
        var score = builtins.float(0.0)
        
        for term in query_terms:
            var term_count = tokens.count(term)
            var tf = builtins.float(0.0)
            
            if term_count > 0:
                tf = 1.0 + math.log(builtins.float(term_count))
            
            var doc_freq = term_doc_freq[term]
            var idf = builtins.float(0.0)
            
            if doc_freq > 0:
                idf = math.log(builtins.float(total_passages) / builtins.float(doc_freq))
            
            score = score + (tf * idf)
        
        if passage_length > 0:
            score = score / math.sqrt(passage_length)
        
        passage["score"] = score
    
    # Sort by score
    var sorted_passages = builtins.sorted(passages, key=Python.evaluate("lambda x: x['score']"), reverse=True)
    
    # Display results
    var n = builtins.min(top_n, total_passages)
    
    for i in range(n):
        var passage = sorted_passages[i]
        var score = passage["score"]
        
        if score <= 0.0:
            break
        
        var score_str = String(score)
        if len(score_str) > 6:
            score_str = score_str[:6]
        
        print("[" + String(i + 1) + "] Score:", score_str, "(page " + String(passage["page"]) + ")")
        
        var text = String(passage["text"]).replace("\n", " ")
        var snippet_len = min(250, len(text))
        var snippet = text[:snippet_len]
        
        print(snippet + "...")
        print()
    
    print("=" * 80)
    print("Search completed successfully!")
    print("=" * 80)