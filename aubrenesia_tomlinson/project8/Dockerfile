FROM ocaml/opam:ubuntu-24.04

WORKDIR /app

# Install dune inside the opam environment
RUN opam update && opam install -y dune

# Copy project files
COPY . /app

# Build project
RUN opam exec -- dune build

# Run the executable
CMD ["opam", "exec", "--", "dune", "exec", "./main.exe"]
