# Project 8 Dockerfile — OCaml functional analytics

FROM ocaml/opam:debian-12

# Install CSV library and ocamlfind
RUN opam update && opam install -y csv ocamlfind

WORKDIR /app

# Ensure src and data directories exist
RUN mkdir -p /app/src /app/data

# Copy source and data
COPY src/main.ml /app/src/main.ml
COPY data /app/data

# Build: compile a standalone binary
RUN cd /app/src && opam exec -- ocamlfind ocamlopt -linkpkg -package csv -o ../app main.ml

# Default runtime environment variable
ENV CSV_PATH=/app/data/baltimore_homicides_combined.csv

# Run the compiled binary
CMD ["./app"]
