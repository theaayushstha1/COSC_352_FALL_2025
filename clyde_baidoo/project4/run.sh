#!/bin/bash
set -e

docker build -t baltimore-homicides .

docker run --rm baltimore-homicides
