import sys
import fitz

def extract(p):
    d = fitz.open(p)
    t = []
    for pg in d:
        t.append(pg.get_text())
    return "\n".join(t)

def passages(t):
    return t.split("\n\n")

def freqs(t, terms):
    f = {}
    l = t.lower()
    for x in terms:
        f[x] = l.count(x)
    return f

def score(p, terms, f):
    s = 0
    w = p.lower().split()
    for t in terms:
        c = w.count(t)
        if c > 0:
            r = 1/(1+f[t])
            s += c*r
    return s

def run():
    if len(sys.argv) < 4:
        print("usage: pdfsearch file \"query\" n")
        return
    path = sys.argv[1]
    q = sys.argv[2].lower()
    n = int(sys.argv[3])
    terms = q.split()
    text = extract(path)
    ps = passages(text)
    f = freqs(text, terms)
    out = []
    for p in ps:
        sc = score(p, terms, f)
        if sc > 0:
            out.append((sc,p))
    out.sort(key=lambda x: x[0], reverse=True)
    for i,(sc,p) in enumerate(out[:n],1):
        print(f"[{i}] {sc}\n{p}\n")

run()
