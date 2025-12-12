from collections import List

fn normalize(text: String) -> String:
    var s = text.lower()

    # Replace common punctuation with spaces
    s = s.replace(",", " ")
    s = s.replace(".", " ")
    s = s.replace(";", " ")
    s = s.replace(":", " ")
    s = s.replace("!", " ")
    s = s.replace("?", " ")
    s = s.replace("(", " ")
    s = s.replace(")", " ")
    s = s.replace("[", " ")
    s = s.replace("]", " ")
    s = s.replace("{", " ")
    s = s.replace("}", " ")
    s = s.replace("-", " ")
    s = s.replace("—", " ")
    s = s.replace("/", " ")
    s = s.replace("\\", " ")
    s = s.replace("\"", " ")
    s = s.replace("'", " ")
    s = s.replace("&", " ")

    return s

fn tokenize(text: String) -> List[String]:
    var clean = normalize(text)
    var parts = clean.split(" ")

    var tokens = List[String]()
    for part_slice in parts:
        if len(part_slice) != 0:
            var token = String(part_slice)
            tokens.append(token)

    # List is not implicitly copyable, so return a copy
    return tokens.copy()



