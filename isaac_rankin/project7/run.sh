#!/bin/bash

docker build -t baltimore-homicides .
docker run -d -p 3838:3838 --name baltimore-homicides-container baltimore-homicides

sleep 3

xdg-open "http://localhost:3838/app/"