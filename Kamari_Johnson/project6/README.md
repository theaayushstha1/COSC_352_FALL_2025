# Project 6 – Golang Port of Project 5

Creator: Kamari Johnson

This project is a Golang version of Project 5. It reads structured data and outputs both CSV and JSON files. The program is written using Go’s standard libraries and is containerized using Docker. It demonstrates how the same functionality from Scala can be implemented in Go with a simpler syntax and faster compilation.

To run the program locally, use:
go run main.go

To run the program in Docker:
docker build -t project6 .
docker run --rm project6

The output files will be created in the output/ directory:
- results.csv
- results.json

Differences between Scala and Go:
Scala is a functional and object-oriented language that runs on the JVM. It uses advanced features like pattern matching, immutability, and monads for error handling. Go is a procedural language with built-in concurrency, simple syntax, and fast native compilation. Go handles errors explicitly and is easier to containerize due to its lightweight runtime.

