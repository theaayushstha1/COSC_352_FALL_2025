// pdfsearch_simd.mojo
// Usage:
// mojo run pdfsearch_simd.mojo <pages.jsonl> "<query>" <N> [--simd] [--window K] [--bench]
//
// Notes:
// - --simd: use SIMD-like tokenizer for passages and query
// - --bench: prints timing for tokenization & scoring (scalar vs SIMD if both modes run)

import json
import sys
import time

struct Passage:
    page: Int
    text: str
    tokens: [str]
    length: Int

struct Document:
    passages: [Passage]

const DEFAULT_WINDOW: Int = 3
const STOPWORDS: [str] = [
    "the","is","at","which","on","and","a","an","of","in","to","for","with","by",
    "that","this","it","as","are","was","be","from","or","we","they","their","have","has","had",
    "but","not","these","those","so","if","then","than","its","also","into","about","over","under"
]

// ---------- utilities ----------
fn strip(s: str) -> str:
    var start: Int = 0
    var end: Int = s.len()
    while start < end and (s[start].ord() == 32 or s[start].ord() == 10 or s[start].ord() == 13 or s[start].ord() == 9):
        start += 1
    while end > start and (s[end-1].ord() == 32 or s[end-1].ord() == 10 or s[end-1].ord() == 13 or s[end-1].ord() == 9):
        end -= 1
    return s.slice(start, end)

fn normalize_token(tok: str) -> str:
    var out: [u8] = []
    for b in tok.bytes():
        if b >= 65 and b <= 90:
            out.append(b + 32)
        else:
            if (b >= 97 and b <= 122) or (b >= 48 and b <= 57) or b == 45 or b == 95:
                out.append(b)
    return out.decode_utf8()

// ---------- scalar tokenizer ----------
fn scalar_tokenize(text: str) -> [str]:
    var toks: [str] = []
    var cur: [u8] = []
    for b in text.bytes():
        if b == 32 or b == 10 or b == 13 or b == 9 or (b >= 33 and b <= 47) or (b >= 58 and b <= 64) or (b >= 91 and b <= 96) or (b >= 123 and b <= 126):
            if cur.len() > 0:
                toks.append(normalize_token(cur.decode_utf8()))
                cur.clear()
        else:
            cur.append(b)
    if cur.len() > 0:
        toks.append(normalize_token(cur.decode_utf8()))
    return toks

// ---------- SIMD-like tokenizer (8-byte u64 chunk micro-optimization) ----------
fn simd_tokenize_like(text: str) -> [str]:
    var toks: [str] = []
    let bytes = text.bytes()
    let n = bytes.len()
    var i: Int = 0
    var cur: [u8] = []
    while i + 8 <= n:
        var chunk: u64 = 0u64
        var j: Int = 0
        while j < 8:
            chunk = chunk | ((u64(bytes[i+j]) & 0xff) << (j * 8))
            j += 1
        var has_sep: Bool = False
        j = 0
        while j < 8:
            let bv = Int((chunk >> (j * 8)) & 0xff)
            if bv == 32 or bv == 10 or bv == 13 or bv == 9 or (bv >= 33 and bv <= 47) or (bv >= 58 and bv <= 64) or (bv >= 91 and bv <= 96) or (bv >= 123 and bv <= 126):
                has_sep = True
                break
            j += 1
        if has_sep:
            j = 0
            while j < 8:
                let b = bytes[i+j]
                if b == 32 or b == 10 or b == 13 or b == 9 or (b >= 33 and b <= 47) or (b >= 58 and b <= 64) or (b >= 91 and b <= 96) or (b >= 123 and b <= 126):
                    if cur.len() > 0:
                        toks.append(normalize_token(cur.decode_utf8()))
                        cur.clear()
                else:
                    cur.append(b)
                j += 1
            i += 8
        else:
            j = 0
            while j < 8:
                cur.append(bytes[i+j])
                j += 1
            i += 8
    while i < n:
        let b = bytes[i]
        if b == 32 or b == 10 or b == 13 or b == 9 or (b >= 33 and b <= 47) or (b >= 58 and b <= 64) or (b >= 91 and b <= 96) or (b >= 123 and b <= 126):
            if cur.len() > 0:
                toks.append(normalize_token(cur.decode_utf8()))
                cur.clear()
        else:
            cur.append(b)
        i += 1
    if cur.len() > 0:
        toks.append(normalize_token(cur.decode_utf8()))
    return toks

fn tokenize(text: str, use_simd: Bool) -> [str]:
    if use_simd:
        return simd_tokenize_like(text)
    else:
        return scalar_tokenize(text)

// ---------- sentence to passage ----------
fn split_into_sentences(text: str) -> [str]:
    var sents: [str] = []
    var cur: [u8] = []
    for b in text.bytes():
        cur.append(b)
        if b == 46 or b == 63 or b == 33:
            let s = strip(cur.decode_utf8())
            if s.len() > 0:
                sents.append(s)
            cur.clear()
    if cur.len() > 0:
        let tail = strip(cur.decode_utf8())
        if tail.len() > 0:
            sents.append(tail)
    return sents

fn build_passages_from_pages(pages_jsonl: str, use_simd: Bool, window_sentences: Int) -> Document:
    var passages: [Passage] = []
    var f = open(pages_jsonl, "r")
    if f == None:
        print("Cannot open %s" % pages_jsonl)
        return Document(passages=passages)
    while True:
        let line = f.readline()
        if line == "":
            break
        let obj = json.loads(line)
        let page = Int(obj["page"])
        let text = str(obj["text"])
        let sents = split_into_sentences(text)
        let s_count = sents.len()
        if s_count == 0:
            let ptext = strip(text)
            if ptext.len() > 0:
                let toks_all = tokenize(ptext, use_simd)
                var toks_filtered: [str] = []
                for t in toks_all:
                    if t.len() == 0: continue
                    var skip: Bool = False
                    for sw in STOPWORDS:
                        if t == sw:
                            skip = True
                            break
                    if not skip:
                        toks_filtered.append(t)
                let p = Passage(page=page, text=ptext, tokens=toks_filtered, length=toks_filtered.len())
                passages.append(p)
            continue
        var i: Int = 0
        while i < s_count:
            let end_idx = if i + window_sentences <= s_count { i + window_sentences } else { s_count }
            var ptext_builder: str = ""
            var j: Int = i
            while j < end_idx:
                if ptext_builder.len() > 0:
                    ptext_builder = ptext_builder + " "
                ptext_builder = ptext_builder + sents[j]
                j += 1
            let ptextg = strip(ptext_builder)
            if ptextg.len() > 0:
                let toks_all = tokenize(ptextg, use_simd)
                var toks_filtered: [str] = []
                for t in toks_all:
                    if t.len() == 0: continue
                    var skip: Bool = False
                    for sw in STOPWORDS:
                        if t == sw:
                            skip = True
                            break
                    if not skip:
                        toks_filtered.append(t)
                let p = Passage(page=page, text=ptextg, tokens=toks_filtered, length=toks_filtered.len())
                passages.append(p)
            i += 1
    f.close()
    return Document(passages=passages)

// ---------- inverted index ----------
fn build_inverted_index(doc: Document) -> (map[str, [Int]], map[str, Int], map[str, Int]):
    // returns (inverted_index, df, cf)
    var inv: map[str, [Int]] = map[str, [Int]]()
    var df: map[str, Int] = map[str, Int]()
    var cf: map[str, Int] = map[str, Int]()
    var i: Int = 0
    for p in doc.passages:
        var seen: map[str, Bool] = map[str, Bool]()
        for t in p.tokens:
            if t.len() == 0: continue
            cf[t] = (cf.get(t) or 0) + 1
            if (seen.get(t) or False) == False:
                df[t] = (df.get(t) or 0) + 1
                seen[t] = True
                var lst = inv.get(t) or []
                lst.append(i)
                inv[t] = lst
        i += 1
    return (inv, df, cf)

fn score_passage_BM25(p: Passage, query_terms: [str], df: map[str, Int], total_passages: Int, avg_pass_len: Float) -> Float:
    let k1 = 1.5
    let b = 0.75
    var score: Float = 0.0
    for q in query_terms:
        var tf: Float = 0.0
        for t in p.tokens:
            if t == q:
                tf += 1.0
        if tf == 0.0: continue
        let dfv = (df.get(q) or 0)
        var idf: Float
        if dfv > 0:
            idf = max(0.01, log( (Float(total_passages) - Float(dfv) + 0.5) / (Float(dfv) + 0.5) ))
        else:
            idf = log(Float(total_passages) + 1.0)
        let denom = tf + k1 * (1.0 - b + b * (Float(p.length) / avg_pass_len))
        score = score + ( (tf * (k1 + 1.0)) / denom ) * idf
    return score

fn print_usage() -> None:
    print("Usage: pdfsearch_simd <pages.jsonl> \"query\" N [--simd] [--window K] [--bench]")

fn main() -> Int:
    if sys.argv.len() < 4:
        print_usage()
        return 1
    let pages_jsonl = sys.argv[1]
    let query = sys.argv[2]
    let topN = Int(sys.argv[3])
    var use_simd: Bool = False
    var window_sentences: Int = DEFAULT_WINDOW
    var bench: Bool = False
    var idx: Int = 4
    while idx < sys.argv.len():
        let arg = sys.argv[idx]
        if arg == "--simd":
            use_simd = True
            idx += 1
        elif arg == "--window" and idx + 1 < sys.argv.len():
            window_sentences = Int(sys.argv[idx+1])
            idx += 2
        elif arg == "--bench":
            bench = True
            idx += 1
        else:
            idx += 1

    // build passages (tokenized per use_simd)
    let t0 = time.time()
    let doc = build_passages_from_pages(pages_jsonl, use_simd, window_sentences)
    let t_pass = time.time() - t0
    let total_passages = doc.passages.len()
    if total_passages == 0:
        print("No passages found.")
        return 1

    var sum_len: Int = 0
    for p in doc.passages:
        sum_len += p.length
    let avg_pass_len = if sum_len > 0 { Float(sum_len) / Float(total_passages) } else { 1.0 }

    // build inverted index
    let t1 = time.time()
    let (inv, df, cf) = build_inverted_index(doc)
    let t_inv = time.time() - t1

    // tokenize query
    let t_q0 = time.time()
    let qtokens_all = tokenize(query, use_simd)
    var qtokens: [str] = []
    for t in qtokens_all:
        if t.len() == 0: continue
        var skip: Bool = False
        for sw in STOPWORDS:
            if t == sw:
                skip = True
                break
        if not skip:
            qtokens.append(t)
    let t_q = time.time() - t_q0

    if qtokens.len() == 0:
        print("No query tokens after stopword removal.")
        return 1

    // candidate passage set via inverted index union
    var candidates_set: map[Int, Bool] = map[Int, Bool]()
    for q in qtokens:
        let lst = inv.get(q) or []
        for idxp in lst:
            candidates_set[idxp] = True

    var candidates: [Int] = []
    for (k, v) in candidates_set:
        if v:
            candidates.append(k)

    // If no candidates (query terms absent), fallback: score all passages
    if candidates.len() == 0:
        var i2: Int = 0
        while i2 < total_passages:
            candidates.append(i2)
            i2 += 1

    // score only candidates
    var scored: [(Float, Int, Passage)] = []
    let t_score0 = time.time()
    for idxp in candidates:
        let p = doc.passages[idxp]
        let s = score_passage_BM25(p, qtokens, df, total_passages, avg_pass_len)
        if s > 0.0:
            scored.append((s, idxp, p))
    let t_score = time.time() - t_score0

    // sort descending
    scored.sort_by(lambda a,b: -1 if a[0] > b[0] else (1 if a[0] < b[0] else 0))

    // print results
    print("Results for: \"%s\"\n" % query)
    var printed = 0
    var rank = 1
    for item in scored:
        if printed >= topN: break
        let score = item[0]
        let p = item[2]
        var snippet = p.text
        if snippet.len() > 300:
            snippet = snippet.slice(0,300) + "..."
        print("[%d] Score: %.2f (page %d)\n    \"%s\"\n" % (rank, score, p.page, snippet))
        printed += 1
        rank += 1

    if printed == 0:
        print("No matching passages found.")

    // bench summary
    if bench:
        print("Timings (s): passage_build=%.3f inv_index=%.3f query_tokenize=%.3f scoring=%.3f total_passages=%d candidates=%d" % (t_pass, t_inv, t_q, t_score, total_passages, candidates.len()))

    return 0
