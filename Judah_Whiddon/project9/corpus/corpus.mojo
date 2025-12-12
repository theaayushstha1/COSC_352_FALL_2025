from collections import List
from tokenizer import tokenize  # (import kept for future use if needed)

struct Passage(Copyable, Movable):
    var id: String
    var page: Int
    var text: String

    fn __init__(out self, id: String, page: Int, text: String):
        self.id = id
        self.page = page
        self.text = text

fn build_corpus() -> List[Passage]:
    var corpus = List[Passage]()

    # Page numbers are placeholders; adjust to match the actual PDF if desired.
    corpus.append(Passage(
        "vision",
        4,
        "Morgan State University is the premier public urban research university in Maryland, known for excellence in teaching, intensive research, effective public service and community engagement. Morgan prepares diverse and competitive graduates for success in a global, interdependent society."
    ))

    corpus.append(Passage(
        "mission",
        5,
        "Morgan State University serves the community, region, state, nation and world as an intellectual and creative resource by supporting, empowering and preparing high-quality, diverse graduates to lead the world. The University offers innovative, inclusive and distinctive educational experiences to a broad cross-section of the population."
    ))

    corpus.append(Passage(
        "goal3_r1",
        12,
        "Morgan will emerge as an R1 doctoral research university fully engaged in basic and applied research and creative interdisciplinary inquiries undergirded and sustained through increased research grants and contracts."
    ))

    return corpus.copy()
