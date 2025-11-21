# Baltimore Homicides Analysis

Analyzes Baltimore homicide data using Clojure.

## Run It
```bash
docker build -t homicides-analysis .
docker run homicides-analysis
```

## What You Get

- Homicides per year with trends
- Top 10 neighborhoods
- Case closure rates
- Camera surveillance stats
- Victim age data

## Files

- `project.clj` - Build config
- `Dockerfile` - Container setup
- `src/homicides_analysis/core.clj` - Main code

## Requirements

Docker
