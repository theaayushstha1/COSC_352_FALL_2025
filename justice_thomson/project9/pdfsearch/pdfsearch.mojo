from python import Python
from sys import argv
from math import log, sqrt

# ------------------------------------------------------
# Normalize text: lowercase + keep letters/spaces only
# ------------------------------------------------------
fn normalize(text: String) -> String:
    var out = String("")
    var n = len(text)
    var i = 0
    while i < n:
        var ch = text[i]
        var code = ord(ch)
        if code >= 65 and code <= 90:  # A–Z
            out += chr(code + 32)
        elif (ch >= "a" and ch <= "z") or ch == " ":
            out += ch
        else:
            out += " "
        i += 1
    return out

# ------------------------------------------------------
# Tokenizer: returns List[String]
# ------------------------------------------------------
fn tokenize(text: String) -> List[String]:
    var clean = normalize(text)
    var slices = clean.split()  # List[StringSlice]
    var result = List[String]()
    for s in slices:
        result.append(String(s))  # Direct conversion from StringSlice
    return result^

# ------------------------------------------------------
# Main TF–IDF PDF search engine
# ------------------------------------------------------
fn main() raises:
    var args = argv()
    if len(args) < 4:
        print("Usage: mojo pdfsearch.mojo <pdf> <query> <N>")
        return

    var pdf_path = args[1]
    var query = args[2]
    var top_n = atol(args[3])

    # Python imports
    var pypdf2 = Python.import_module("PyPDF2")
    var builtins = Python.import_module("builtins")

    print("\nExtracting PDF:", pdf_path)

    # Open PDF
    var f = builtins.open(pdf_path, "rb")
    var reader = pypdf2.PdfReader(f)
    var num_pages: Int = Int(builtins.len(reader.pages).__int__())

    print("Total pages:", num_pages)

    # Store passages
    var passages = Python.evaluate("[]")

    # Extract passages page by page
    var page_index = 0
    while page_index < num_pages:
        var page = reader.pages[page_index]
        var text_obj = page.extract_text()

        # Check if text extraction returned None or empty string
        if text_obj.__bool__() == False or builtins.len(text_obj) == 0:
            page_index += 1
            continue

        var text: String = String(text_obj)

        var chunks = text.split("\n\n")
        for chunk in chunks:
            var para = chunk.strip()
            if len(para) > 50:
                var obj = Python.evaluate("{'text': '', 'page': 0, 'score': 0.0}")
                obj["text"] = para
                obj["page"] = page_index + 1
                passages.append(obj)

        page_index += 1

    f.close()
    var total_passages: Int = Int(builtins.len(passages).__int__())
    print("Extracted", total_passages, "passages\n")

    # Query processing
    var query_norm = normalize(query)
    var query_tokens = tokenize(query_norm)

    if len(query_tokens) == 0:
        print("No valid query terms found.")
        return

    print("Query terms:", query_tokens, "\n")

    # Document Frequency
    var df = Python.evaluate("{}")
    for term_obj in query_tokens:
        var term = term_obj
        var count = 0
        for p in passages:
            var txt = String(p["text"]).lower()
            if term in txt:
                count += 1
        df[term] = count

    # TF-IDF Scoring
    for p in passages:
        var txt = String(p["text"]).lower()
        var tokens = tokenize(txt)
        var L = len(tokens)
        var score: Float64 = 0.0

        for term_obj in query_tokens:
            var term = term_obj
            var tf_count = 0
            for t in tokens:
                if t == term:
                    tf_count += 1

            var tf: Float64 = 1.0 + log(Float64(tf_count)) if tf_count > 0 else 0.0
            var df_val: Int = Int(df[term].__int__()) if term in df else 0
            var idf: Float64 = log(Float64(total_passages) / Float64(df_val)) if df_val > 0 else 0.0
            score += tf * idf

        if L > 0:
            score = score / sqrt(Float64(L))

        p["score"] = score

    # Sort results
    var sorted_passages = builtins.sorted(
        passages,
        key=Python.evaluate("lambda x: -x['score']")
    )

    # Display top N
    var N = min(top_n, total_passages)
    print("\nTop results:\n")
    var i = 0
    while i < N:
        var p = sorted_passages[i]
        # Work with Python object directly for display
        var py_score = p["score"]
        var score_str = String(py_score.__str__())
        
        # Check if score is effectively zero
        var score_val = Float64(score_str)
        if score_val <= 0.0:
            break

        # Truncate score string for display
        if len(score_str) > 6:
            score_str = String(score_str[:6])

        print("[", i+1, "] Score:", score_str, "(page", Int(p["page"].__int__()), ")")
        var snippet = String(p["text"]).replace("\n", " ")
        if len(snippet) > 250:
            snippet = String(snippet[:250]) + "..."

        print(snippet, "\n")
        i += 1

    print("Search complete!\n")