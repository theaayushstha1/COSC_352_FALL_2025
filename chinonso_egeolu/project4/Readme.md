# Project 4: Baltimore Homicide Data Analyzer

Analyzes Baltimore homicide statistics using Scala and Stack data structures to identify critical crime patterns.

## Questions Answered

1. **Violence Escalation Patterns** - Identifies "hot streaks" of consecutive incidents within 7-day windows to predict retaliatory violence
2. **Hot Spot Migration** - Tracks how violence moves between districts to predict next affected areas

## Tech Stack

- Scala 2.13.6 with native libraries only
- Stack data structure for pattern detection
- Docker containerized
- No external dependencies

## Quick Start

```bash
cd chinonso_egeolu/project4
chmod +x run.sh
./run.sh
```

## Project Structure

```
chinonso_egeolu/project4/
├── HomicideAnalysis.scala
├── build.sbt
├── Dockerfile
├── run.sh
└── README.md
```

## Native Libraries Used

- `scala.collection.mutable.Stack` - Pattern detection
- `java.time.*` - Date operations
- Standard Scala collections

## Troubleshooting

**Rebuild image:**
```bash
docker rmi baltimore-homicide-analysis && ./run.sh
```

**Permission error:**
```bash
chmod +x run.sh
```

