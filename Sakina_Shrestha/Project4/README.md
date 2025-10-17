# Project 4 — Sakina Shrestha

Native Scala program that fetches the public Baltimore homicide list from chamspage and answers two original questions with only standard Scala.

## Questions answered

- Q1: How do case closure rates differ when a surveillance camera is present versus absent at the intersection? (also reports average victim age)  

WITH camera: count=23 closed=9 rate=39.13% avgAge=35.17

WITHOUT camera: count=76 closed=25 rate=32.89% avgAge=35.486

Insight: Presence of cameras corresponds to a 6.24% absolute difference in closure rate.

- Q2: What are closure rates by likely cause inferred from Notes (Shooting vs Stabbing vs Other)?  

Blunt Force: count=1 closed=1 rate=100.00% avgAge=43.0

Other: count=13 closed=2 rate=15.38% avgAge=44.69

Shooting: count=76 closed=25 rate=32.89% avgAge=32.851

Stabbing: count=9 closed=6 rate=66.67% avgAge=42.22

Insight: Highest closure rate category = Blunt Force at 100.00%; lowest = Other at 15.38%.


## Quickstart

From this folder (contains Dockerfile and run.sh):


