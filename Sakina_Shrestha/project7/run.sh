#!/bin/bash

# Build Docker image
docker build -t baltimore-homicide-dashboard .

# Run container WITHOUT --rm so it stays after crash
docker run -p 3838:3838 baltimore-homicide-dashboard
