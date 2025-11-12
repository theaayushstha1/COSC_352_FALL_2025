# Project 6 — Baltimore Homicide Data (Golang)

This project is a Golang version of Project 5, which was originally implemented in Scala. It reads homicide data from both a CSV and JSON file and prints the information to the console.

## 🧩 Functionality
- Reads data from `baltimore_homicide_answers.csv`
- Parses JSON from `baltimore_homicide_answers.json`
- Displays both in a structured format

## 🚀 How to Run

### Local
```bash
go run main.go
```

### Docker
```bash
docker build -t baltimore-homicide .
docker run --rm baltimore-homicide
```

---

## ⚙️ Key Differences (Scala vs Golang)

| Feature | Scala | Golang |
|----------|--------|--------|
| Language Type | Functional + Object-Oriented | Procedural + Concurrent |
| File Handling | Uses `scala.io.Source` | Uses `os` and `encoding/csv` |
| JSON Parsing | Uses external libraries (like play-json) | Native `encoding/json` |
| Compilation | JVM-based | Native binary compilation |
| Concurrency | Actors / Futures | Goroutines and Channels |
| Performance | Slower startup (JVM) | Faster startup and execution |

---

## 📚 Resources
- [Official Golang site](https://go.dev/)
- [Docker Hub Go Image](https://hub.docker.com/_/golang)
- [Go CSV Docs](https://pkg.go.dev/encoding/csv)
- [Go JSON Docs](https://pkg.go.dev/encoding/json)
