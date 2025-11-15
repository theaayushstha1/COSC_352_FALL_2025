#!/usr/bin/env bash

# Build image
docker build -t baltimore-homicides-shiny .

# Run container
docker run --rm -p 3838:3838 baltimore-homicides-shiny
