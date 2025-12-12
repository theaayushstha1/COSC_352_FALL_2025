# Project 4: Baltimore City Homicide Data Analysis

**Author:** Aayush Shrestha  
**Course:** COSC 352 - Fall 2025  
**Institution:** Morgan State University

## Overview

This project analyzes Baltimore City homicide statistics from chamspage.blogspot.com using Scala (JVM). The program answers two critical questions to help the Mayor's office and Baltimore Police Department optimize resource allocation and reduce violent crime through data-driven policy decisions.

## Questions Analyzed

### Question 1: Violence Interruption Zone Deployment Strategy
**Question:** Which specific street locations have the highest homicide concentrations, and should Baltimore implement 'Violence Interruption Zones' at these hotspots?

**Objective:** Identify micro-geographic clusters of violence to enable targeted deployment of Violence Interruption specialists, enhanced street lighting, community programs, and focused police presence.

**Strategic Value:** 
- Reveals concentrated violence patterns suggesting systemic issues (drug markets, gang territories, social disorder)
- Enables precise resource deployment to highest-impact locations
- Disrupts cycles of retaliatory violence through targeted intervention
- Provides data-driven justification for community policing budget allocation

**Key Findings:**
- Identifies critical hotspots with 3+ homicides requiring immediate intervention
- Analyzes camera coverage gaps at high-violence locations
- Calculates percentage of total homicides occurring in concentrated zones
- Recommends specific streets for Violence Interruption Zone establishment

### Question 2: Age-Based Investigative Resource Allocation
**Question:** What is the correlation between victim age demographics and case closure success rates, revealing which age groups need targeted investigative resources?

**Objective:** Identify disparities in homicide case closure rates across different victim age groups to optimize detective unit specialization and resource allocation.

**Strategic Value:**
- Reveals which demographics have lower case closure rates due to investigative challenges
- Enables targeted deployment of specialized detective units (juvenile, elder abuse, gang specialists)
- Identifies witness cooperation and community engagement barriers
- Maximizes case clearance effectiveness through demographic-specific approaches

**Key Findings:**
- Analyzes closure rates for 5 age groups: Minors, Young Adults, Adults, Middle Age, Seniors
- Identifies underperforming demographics requiring additional investigative resources
- Calculates closure rate disparities between highest and lowest performing groups
- Recommends specialized detective unit deployment for vulnerable demographics

## Technical Implementation

- **Language:** Scala 2.13.12
- **Runtime:** OpenJDK 17 (JVM)
- **Containerization:** Docker
- **Libraries:** Native Scala/Java only (scala.io.Source, java.time.*, scala.util.Try)
- **Data Source:** Live web scraping from chamspage.blogspot.com with fallback to sample data

## Project Structure

