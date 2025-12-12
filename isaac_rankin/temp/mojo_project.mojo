from collections.dict import Dict
from collections.list import List
from os.file import File
from sys import print

@value
struct Passage:
    
    var page: Int
    var text: String
    var tf_map: Dict[String, Int] = Dict[String, Int]()
    var score: Float64 = 0.0


fn tokenize_and_count(passage_text: String) -> Dict[String, Int]:


    var tf_map = Dict[String, Int]()

    let delimiters = " "
    let tokens = passage_text.split(delimiters)
    
    for token_slice in tokens:
        var token = String(token_slice).to_lower()
        
        token = token.remove_prefix("\"")
        token = token.remove_suffix("\"")
        token = token.remove_suffix(",")
        token = token.remove_suffix(".")
        
        if len(token) > 0:
            var current_count = tf_map.get(token, 0)
            tf_map[token] = current_count + 1
            
    return tf_map


fn load_and_tokenize_corpus(filename: String) -> List[Passage]:

    var passages = List[Passage]()
    let file = File(filename)

    let full_content = file.read_text()

    let lines = full_content.split("\n")
    
    for line_slice in lines:
        var line = String(line_slice)
        
        let separator_index = line.find("|")
        
        if separator_index != -1:

            # Page number
            let page_str = line.substring(0, separator_index)
            let page_num = page_str.to_int()
            
            # Passage text
            let text = line.substring(separator_index + 1)
            
            # Tokenize
            let tf_map = tokenize_and_count(text)
            
            passages.append({
                page: page_num, 
                text: text, 
                tf_map: tf_map
            })
            
    return passages

fn main():
    let corpus = load_and_tokenize_corpus("pdf_text.txt")
    
    print("Loaded", len(corpus), "passages.")
    
    if len(corpus) > 0:
        print("\n--- First Passage Bag of Words (TF Map) ---")
        let first_passage = corpus[0]
        print("Page:", first_passage.page)
        
        # Iterate over the Bag of Words dictionary
        for entry in first_passage.tf_map.items():
            print(entry.key, ":", entry.value)