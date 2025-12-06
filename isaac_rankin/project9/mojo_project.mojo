from collections.dict import Dict
from collections.list import List
from os.file import File
from sys import print
from math import log

@value
struct Passage:
    var page: Int
    var text: String
    var tf_map: Dict[String, Int] = Dict[String, Int]()
    var score: Float64 = 0.0


fn clean_token(token: String) -> String:
    var t = token.to_lower()

    t = t.remove_prefix("\"")
    t = t.remove_suffix("\"")
    t = t.remove_suffix(",")
    t = t.remove_suffix(".")
    t = t.remove_suffix("?")
    t = t.remove_suffix("!")
    t = t.remove_prefix("(")
    t = t.remove_suffix(")")
    t = t.remove_suffix(";")
    t = t.remove_suffix(":")
    
    return t


fn tokenize_and_count(text: String) -> Dict[String, Int]:
    var tf_map = Dict[String, Int]()
    let tokens = text.split(" ")

    for token_slice in tokens:
        var token = clean_token(String(token_slice))

        if len(token) > 0:
            var current_count = tf_map.get(token, 0)
            tf_map[token] = current_count + 1

    return tf_map


fn load_and_tokenize_corpus(filename: String) -> List[Passage]:
    var passages = List[Passage]()
    let file = File(filename)
    let content = file.read_text()

    let lines = content.split("\n")

    for line_slice in lines:
        let line = String(line_slice)
        let sep = line.find("|")

        if sep != -1:
            let page_num = line.substring(0, sep).to_int()
            let text = line.substring(sep + 1)

            let tf_map = tokenize_and_count(text)

            passages.append(Passage(
                page=page_num,
                text=text,
                tf_map=tf_map,
                score=0.0
            ))

    return passages

fn compute_document_frequency(passages: List[Passage]) -> Dict[String, Int]:
    var df_map = Dict[String, Int]()

    for p in passages:
        for term in p.tf_map.keys():
            df_map[term] = df_map.get(term, 0) + 1

    return df_map


fn compute_idf(df_map: Dict[String, Int], total_docs: Int) -> Dict[String, Float64]:
    var idf_map = Dict[String, Float64]()

    for entry in df_map.items():
        let term = entry.key
        let df = entry.value

        # Add +1 to prevent division by zero
        let idf = log((total_docs + 1) / (Float64(df) + 1)) + 1
        idf_map[term] = idf

    return idf_map


fn compute_tf_idf_for_passages(passages: List[Passage], idf_map: Dict[String, Float64]):

    for i in range(len(passages)):
        var score: Float64 = 0.0
        let tf = passages[i].tf_map

        for entry in tf.items():
            let term = entry.key
            let freq = Float64(entry.value)

            if idf_map.contains(term):
                score += freq * idf_map[term]

        passages[i].score = score

fn rank_by_query(passages: List[Passage], query: String) -> List[Passage]:

    let query_tf = tokenize_and_count(query)
    var results = List[Passage]()

    for p in passages:
        var relevance: Float64 = 0.0

        for entry in query_tf.items():
            let term = entry.key
            let q_freq = Float64(entry.value)

            if p.tf_map.contains(term):
                let p_freq = Float64(p.tf_map[term])
                relevance += p_freq * q_freq

        if relevance > 0:
            var copy = p
            copy.score = relevance
            results.append(copy)

    # sort descending (selection sort)
    for i in range(len(results)):
        var max_idx = i
        for j in range(i+1, len(results)):
            if results[j].score > results[max_idx].score:
                max_idx = j

        let temp = results[i]
        results[i] = results[max_idx]
        results[max_idx] = temp

    return results


fn main():

    let corpus = load_and_tokenize_corpus("pdf_text.txt")
    print("Loaded", len(corpus), "passages.")

    if len(corpus) == 0:
        return

    let df_map = compute_document_frequency(corpus)
    let idf_map = compute_idf(df_map, len(corpus))

    compute_tf_idf_for_passages(corpus, idf_map)

    let query = "gradient descent optimization"
    let ranked = rank_by_query(corpus, query)

    print("\nTop 5 Results for:", query)

    for i in range(min(5, len(ranked))):
        print("\nPage:", ranked[i].page)
        print("Score:", ranked[i].score)
        print("Text:", ranked[i].text)
