# Project 8 – Baltimore Homicides (Functional Programming)

This project implements a small analytical tool over the Baltimore homicides dataset using a purely functional core written in **OCaml**.

## Analyses

This program performs two analyses over `baltimore_homicides_combined.csv`:

1. **Homicides per year** – counts the total number of homicides for each year in the dataset.
2. **Top 10 neighborhoods by incidence** – ranks neighborhoods by total homicide count and prints the top 10.

All core analysis logic is implemented with immutable data and functional constructs like `map`, `filter`, and `fold`.

## How to Run (Docker)

From the repository root:

```bash
cd christian_douglass/project8
docker build -t baltimore_homicides_ocaml .
docker run --rm baltimore_homicides_ocaml
```

The container will compile and run the OCaml program and print the analysis results to standard output.

## Files

- `src/main.ml` – OCaml source code implementing CSV parsing and analyses.
- `baltimore_homicides_combined.csv` – dataset copied locally from the course repository.
- `Dockerfile` – builds and runs the OCaml program in a container.
