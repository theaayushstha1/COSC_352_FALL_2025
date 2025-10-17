# Homicide Analysis (Scala + Docker)

This project analyzes homicide data from a CSV file, focusing on cases from the year 2024. It filters victims by age and criminal history to answer specific questions.

## 📊 What It Does

- Counts total homicide entries for 2024
- Identifies college-aged victims (18–23)
- Calculates how many victims had no prior violent criminal history

## 🛠 Requirements

- Docker installed and running

## 🚀 How to Run

1. Clone or download this repository
2. Open a terminal in the project folder
3. Build the Docker image:

   ```bash
   docker build -t homicide-analysis .
   docker run --rm homicide-analysis
