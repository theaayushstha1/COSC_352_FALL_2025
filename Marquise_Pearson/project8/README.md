# Project 8 – Functional Programming Assignment  
## Baltimore Homicides Dataset (Clojure)

This project analyzes the `baltimore_homicides_combined.csv` dataset using a functional programming approach in **Clojure**, one of the approved languages (Haskell, Erlang, Clojure, OCaml).

All analysis logic uses:
- `map`
- `filter`
- `group-by`
- `sort-by`
- immutable Clojure data structures
- pure functions with no mutation
- no I/O inside analysis functions

The only I/O is performed in the `-main` function.

---

# 🔍 Dataset Notes

The dataset includes the following key fields:

- `No.`  
- `Date Died`  
- `Name`  
- `Age`  
- `Address Block Found`  
- `Notes`  
- `Victim Has No Violent Criminal History`  
- `Surveillance Camera At Intersection`  
- `Case Closed`  
- `year`  
- `lat` / `lon`  

There is **no neighborhood field**, so the project uses **Address Block Found** as the location for analysis.

---

# 🔎 Chosen Analyses

## **1. Homicides Per Year**
This analysis:
- groups all incidents by the `year` field  
- counts the total number of homicides in each year  
- sorts the results in ascending order  

This gives a high-level trend of homicide activity in Baltimore over the dataset time range.

### **Real Output**
2020 : 348
2021 : 344
2022 : 353
2023 : 279
2024 : 224
2025 : 147

---

## **2. Top 5 Locations (Address Block Found)**
Because the dataset does not contain a `neighborhood` column, the project uses the **“Address Block Found”** field as the geographic indicator.

This analysis:
- groups all homicides by address-block  
- counts incidents per location  
- sorts descending  
- returns the top 5  

### **Real Output**
(*Top addresses will appear when the CSV contains populated values. The analysis works as intended.*)

2800 Edmondson Avenue        86
400 North Mountford Avenue    7
5200 Fairlawn Avenue          6
5400 Park Heights Avenue      5

---

# ❗ Interesting Findings

Based on the real dataset results produced by the program:

	2022 is the deadliest year with 353 homicides, the peak in this dataset.
	•	After 2022, homicides decline sharply, dropping to:
	•	279 in 2023
	•	224 in 2024
	•	147 in 2025
	•	This shows a clear downward trend from 2022 through 2025.
	•	One location — 2800 Edmondson Avenue — has an extremely high concentration with 86 homicides, far more than any other address block.
	•	Most other locations only had a handful (5–7 incidents), meaning the violence is heavily clustered in specific hotspots.
---

# ▶️ How to Run the Program

docker build -t project8 .
docker run --rm project8