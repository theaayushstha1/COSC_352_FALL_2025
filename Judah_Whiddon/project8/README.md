
Runs a simple pure function over the full list of records to get the total number of cases.


Classifies each incident by weapon category (Shooting, Stabbing, etc.) and aggregates totals with a "foldl" function.

 
Erlang Implementation Structure. What was immediately present to me was the there were 3 different modules doing a single thing, which feels like an extrapolation of function purity.

To run the program simply build and run the Docker inmage. cd into my project8 directory and run these commands in order. 
1. "build -t project8".
2. "docker run --rm project8"


