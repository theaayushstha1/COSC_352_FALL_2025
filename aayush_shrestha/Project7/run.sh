#!/bin/bash

# Build Docker image
docker build -t baltimore-homicide-dashboard .

# Run container
docker run --rm -p 3838:3838 baltimore-homicide-dashboard
