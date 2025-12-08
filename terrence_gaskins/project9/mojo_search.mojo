import sys
import json

struct Passage:
    var page: Int
    var text: String
    var score: Float64

fn normalize(text: String) -> String:
    var out = String()
    for ch in text:
        if ch >= 'A' and ch <= 'Z':
            out.append(Char(ch.code_point + 32))
        elif ch.is_alnum():
            out.append(ch)
        else:
            out.append(' ')
    return out

fn tokenize(text: String) -> List[String]:
    var tokens = List[String]()
    var word = String()
    for ch in text:
        if ch == ' ' or ch == '\n':
            if word.size > 0:
                tokens.append(word)
                word = String()
        else:
            word.append(ch)
    if word.size > 0:
        tokens.append(word)
    return tokens

fn load_passages(path: String) -> List[Passage]:
    let file = open(path, "r")
    let raw = file.read_all()
    file.close()
    let data = json.parse(raw)
    var passages = List[Passage]()
    for item in data.as_array():
        let page = item["page"].as_int()
        let text = item["text"].as_string()
        passages.append(Passage(page=page, text=text, score=0.0))
    return passages

fn compute_df(passages: List[Passage], terms: List[String]) -> Dict[String, Int]:
    var df = Dict[String, Int]()
    for t in terms:
        df[t] = 0
    for p in passages:
        let tokens = tokenize(normalize(p.text))
        let unique = Set[String]()
        for tk in tokens:
            unique.insert(tk)
        for t in terms:
            if unique.contains(t):
                df[t] = df[t] + 1
    return df

fn score_passage(p: Passage, terms: List[String], df: Dict[String, Int], total: Int) -> Float64:
    let tokens = tokenize(normalize(p.text))
    var tf = Dict[String, Int]()
    for t in terms:
        tf[t] = 0
    for tk in tokens:
        if tf.has_key(tk):
            tf[tk] = tf[tk] + 1
    var score: Float64 = 0.0
    for t in terms:
        let count = tf[t]
        let tf_scaled = 1.0 + log(1.0 + Float64(count))
        let idf = log((1.0 + Float64(total)) / (1.0 + Float64(df[t])))
        score = score + tf_scaled * idf
    return score / sqrt(Float64(tokens.size) + 1.0)

fn top_n(passages: List[Passage], n: Int) -> List[Passage]:
    passages.sort(by=fn (a: Passage, b: Passage) -> Bool:
        return a.score > b.score
    )
    return passages.slice(0, min(n, passages.size))

fn main():
    if sys.argc() != 4:
        sys.stderr().write("Usage: mojo_search.mojo <passages.json> <query> <N>\n")
        sys.exit(1)
    let json_path = sys.argv()[1]
    let query = sys.argv()[2]
    let n = Int(sys.argv()[3].parse_int())
    let passages = load_passages(json_path)
    let total = passages.size
    let query_terms = tokenize(normalize(query))
    let