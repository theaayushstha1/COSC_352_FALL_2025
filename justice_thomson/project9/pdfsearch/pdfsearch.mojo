from python import Python
from sys import argv

# ------------------------------------------------------------
# Helper: lowercase text (ASCII only)
# ------------------------------------------------------------
fn lower_ascii(text: String) -> String:
    var out = String("")
    var n = len(text)
    var i = 0
    while i < n:
        var ch = text[i]
        var code = ord(ch)
        if code >= 65 and code <= 90:
            out += chr(code + 32)
        else:
            out += ch
        i += 1
    return out


# ------------------------------------------------------------
# Tokenizer: keep only letters + spaces, split on spaces
# ------------------------------------------------------------
fn tokenize(text: String) -> List[String]:
    var cleaned = String("")
    var t = lower_ascii(text)
    var n = len(t)
    var i = 0

    while i < n:
        var ch = t[i]
        if (ch >= "a" and ch <= "z") or ch == " ":
            cleaned += ch
        else:
            cleaned += " "
        i += 1

    return cleaned.split()


# ------------------------------------------------------------
# Short snippet for display
# ------------------------------------------------------------
fn snippet(text: String) -> String:
    var t = text.replace("\n", " ")
    var n = len(t)
    var max_len = 250
    if n <= max_len:
        return t
    return t[0:max_len] + "..."


# ------------------------------------------------------------
# Main Program: TF-IDF PDF search
# ------------------------------------------------------------
fn main() raises:
    var args = argv()

    if len(args) < 4:
        print("Usage: mojo pdfsearch.mojo <pdf_file> <query> <top_n>")
        print("Example:")
        print("  mojo pdfsearch.mojo morgan2030.pdf \"R1 university\" 3")
        return

    var pdf_path = args[1]
    var query = args[2]
    var top_n = Int(args[3])

    var py = Python()
    var pypdf2 = py.import_module("PyPDF2")
    var builtins = py.import_module("builtins")
    var math = py.import_module("math")
    var re = py.import_module("re")

    print("")
    print("============== MOJO PDF SEARCH ENGINE ==============")
    print("PDF:", pdf_path)
    print("Query:", query)
    print("Top N:", top_n)
    print("====================================================")
    print("Extracting text from PDF...\n")

    # ----------------------------------------
    # 1. Extract passages from PDF
    # ----------------------------------------
    var f = builtins.open(pdf_path, "rb")
    var reader = pypdf2.PdfReader(f)
    var num_pages = builtins.len(reader.pages)

    var passages = Python.evaluate("[]")

    var page_index = 0
    while page_index < num_pages:
        var page = reader.pages[page_index]
        var text = page.extract_text()
        if text is None:
            page_index += 1
            continue

        var chunks = text.split("\n\n")
        for chunk in chunks:
            var para = chunk.strip()
            if builtins.len(para) > 50:
                var entry = Python.evaluate("{'text': '', 'page': 0, 'score': 0.0}")
                entry["text"] = para
                entry["page"] = page_index + 1
                passages.append(entry)

        page_index += 1

    f.close()

    var total_passages = builtins.len(passages)
    if total_passages == 0:
        print("No passages extracted from PDF.")
        return

    print("Extracted", total_passages, "passages.\n")

    # ----------------------------------------
    # 2. Process query into terms
    # ----------------------------------------
    var q_lower = query.lower()
    var query_terms = re.findall(r"\b[a-zA-Z]{3,}\b", q_lower)

    if builtins.len(query_terms) == 0:
        print("No valid query terms after preprocessing.")
        return

    print("Query terms:", query_terms, "\n")

    # ----------------------------------------
    # 3. Compute document frequency (DF)
    # ----------------------------------------
    var term_df = Python.evaluate("{}")

    for term in query_terms:
        var count = 0
        for p in passages:
            var t_low = p["text"].lower()
            if term in t_low:
                count += 1
        term_df[term] = count

    # ----------------------------------------
    # 4. Compute TF-IDF for each passage
    # ----------------------------------------
    for p in passages:
        var text_lower = lower_ascii(p["text"])
        var tokens = tokenize(text_lower)
        var length_f = builtins.float(builtins.len(tokens))

        var score = builtins.float(0.0)

        for term in query_terms:
            var term_count = tokens.count(term)

            var tf = builtins.float(0.0)
            if term_count > 0:
                tf = 1.0 + math.log(builtins.float(term_count))

            var df_val = term_df[term]
            var idf = builtins.float(0.0)

            if df_val > 0:
                idf = math.log(
                    builtins.float(total_passages) /
                    builtins.float(df_val)
                )

            score = score + (tf * idf)

        if length_f > 0.0:
            score = score / math.sqrt(length_f)

        p["score"] = score

    # ----------------------------------------
    # 5. Sort by score descending
    # ----------------------------------------
    passages.sort(
        key=Python.evaluate("lambda x: x['score']"),
        reverse=True
    )

    print("============== RESULTS for \"" + query + "\" ==============\n")

    var limit = top_n
    if limit > total_passages:
        limit = total_passages

    var i = 0
    while i < limit:
        var p = passages[i]
        var sc = p["score"]
        if sc <= 0.0:
            break

        var score_str = String(sc)
        if len(score_str) > 6:
            score_str = score_str[0:6]

        print("[" + String(i + 1) + "] Score:", score_str,
              "(page", String(p["page"]), ")")
        print("    \"" + snippet(String(p["text"])) + "\"\n")

        i += 1

    print("===================== SEARCH COMPLETE =====================")
