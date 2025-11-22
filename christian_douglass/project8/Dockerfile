FROM ocaml/opam:alpine-ocaml-5.1

WORKDIR /app

# Install build tools (if needed)
RUN opam update && opam install -y ocamlfind

COPY . /app

# Use the OCaml compiler from the opam switch
RUN eval "$(opam env)" && ocamlc -o baltimore_homicides src/main.ml

CMD ["./baltimore_homicides", "./baltimore_homicides_combined.csv"]
