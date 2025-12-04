#!/bin/bash

docker build -t homicide-analysis .
docker run homicide-analysis
