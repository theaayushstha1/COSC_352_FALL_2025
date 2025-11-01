#!/bin/bash

docker build . --tag scala_app

docker run --rm -v $(pwd)/csv:/app/csv scala_app