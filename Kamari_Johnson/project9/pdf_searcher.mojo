# pdf_searcher.mojo

fn search_text(term: String, text: String, n: Int) -> String:
    var count = 0
    var output = ""
    for line in text.split("\n"):
        if line.find(term) != -1:
            output = output + "Match: " + line + "\n"
            count = count + 1
            if count >= n:
                break
    if count == 0:
        return "No matches found."
    return output

fn main():
    # Stub entrypoint — required by Mojo compiler
    print("pdf_searcher.mojo compiled successfully.")