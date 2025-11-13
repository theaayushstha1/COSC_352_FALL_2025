Project 6 — Port of Project 5 to Go

This project is a Go port of Project 5 (which was written in Scala). It provides the same functionality: scraping the 2025 Baltimore homicide list and producing either textual analysis (default), CSV, or JSON output.

Files added
- `main.go` - Go implementation that scrapes the same URL and supports the same CLI flags `--output` and `--out-file` (see Usage).
- `go.mod` - Go module file (depends on `github.com/PuerkitoBio/goquery` for HTML parsing).
- `Dockerfile` - Official Golang base image used to build the binary and produce a runnable container.
- `run.sh` - Convenience script to build the Docker image and run the container, optionally mounting the project directory.

Usage
- Build locally (requires Go 1.21+):

```bash
cd christian_douglass/project6
go build -o homicide .
# run textual analysis (default)
./homicide
# write CSV to file
./homicide --output=csv
# write CSV to stdout
./homicide --output=csv --out-file=-
# write JSON to host file
./homicide --output=json --out-file=homicides_2025.json
```

- Using Docker (script provided):

```bash
chmod +x project6/run.sh
./project6/run.sh           # build image and run textual analysis
./project6/run.sh --output=csv   # container writes homicides_2025.csv inside container
# to persist outputs to host, run the image with a bind mount (example provided by script)
```

Differences: Scala implementation vs Go implementation

High-level differences implemented and notes for the grader:

- Language/runtime
  - Scala runs on the JVM; the original `Main.scala` uses JSoup (Java library) and sbt for building.
  - Go compiles to a static native binary and uses `goquery` (a Go wrapper for `golang.org/x/net/html`) for HTML parsing. The Go binary is lighter and starts faster compared to a JVM-based image.

- Concurrency and performance
  - The Scala program runs single-threaded here; the Go program is also single-threaded for parity. Go's goroutines could easily be used to parallelize network/IO if needed.

- Dependency management
  - Scala used sbt and Java libraries; Go uses the module system (`go.mod`) and `go get`/`go mod download` to fetch dependencies.

- JSON/CSV handling
  - Scala manual-escaped JSON and CSV writing. Go uses `encoding/csv` and `encoding/json` which provide safe quoting/escaping and stable output.

- CLI flags
  - Both implementations accept `--output` (csv/json) and `--out-file` (path or `-` for stdout). The Go program uses the `flag` package.

- Dockerization
  - The Scala Dockerfile relied on installing sbt in a Java image and running the sbt runner.
  - The Go Dockerfile builds a native binary inside the official `golang` image and sets the binary as the container entrypoint. This creates a simpler runtime image without heavy JVM requirements.

Notes for the quiz
- Go features to mention: static binary compilation, built-in concurrency with goroutines and channels, strong standard library (http, encoding/json, csv), fast startup and small runtime. Go's `go.mod` improves reproducible builds.
- Scala features to contrast: JVM ecosystem, powerful type system, functional programming features (immutable collections, pattern matching), but heavier runtime and slightly slower startup.

If you'd like, I can:
- Add a small test harness for the Go code.
- Produce a multi-stage Dockerfile that yields a minimal final image (scratch or distroless).
- Copy output files out of the container automatically into the project directory during `run.sh`.
