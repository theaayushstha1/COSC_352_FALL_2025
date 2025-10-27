Project 5 - Baltimore Homicide Output Formats

This project contains a copy of the Project 4 scraper but with explicit CSV/JSON output and a run script that bind-mounts the project directory so produced files are available on the host.

Files:
- `Main.scala` - Scala program that scrapes the 2025 Baltimore homicide list and can write CSV or JSON.
- `build.sbt` - sbt build file with dependencies.
- `Dockerfile` - builds an image that runs the program.
- `run.sh` - builds (if needed) and runs the container, and mounts the project folder into the container so output files persist.

Usage
1) Make the runner executable:

```bash
chmod +x project5/run.sh
```

2) Build and run, default textual analysis printed to stdout:

```bash
./project5/run.sh
```

3) Write CSV to host directory (file will be `project5/homicides_2025.csv`):

```bash
./project5/run.sh --output=csv
```

4) Write JSON to host directory (file will be `project5/homicides_2025.json`):

```bash
./project5/run.sh --output=json
```

Format details
- CSV header: no,date,name,age,address,notes,criminalHistory,camera,caseClosed
  - Fields containing commas/quotes/newlines are quoted; double quotes inside fields are escaped by doubling.
  - Missing ages are empty strings.
- JSON: array of objects. `age` is number or null when missing.

Notes
- The run script bind-mounts the project directory into the container: outputs written by the program will be available back on your host in the `project5` directory.
- If you'd rather stream CSV/JSON to stdout (so you can pipe it) I can update the program to print to stdout instead of writing files.
