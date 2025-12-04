FROM ocaml/opam:debian-11-ocaml-4.14

USER root

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /work

COPY homicide_analysis.ml /work/

RUN opam init --disable-sandboxing -y -a && \
    eval $(opam env) && \
    ocamlopt -o homicide_analysis homicide_analysis.ml

RUN chmod +x homicide_analysis

ENTRYPOINT ["/work/homicide_analysis"]