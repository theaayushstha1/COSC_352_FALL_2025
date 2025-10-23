Project 4 - Baltimore Homicide Insights

Contents:
- `Main.scala` - Scala program that downloads the 2025 Baltimore homicide table and answers two questions.
- `Dockerfile` - Builds a container with sbt and runs the Scala program.
- `run.sh` - Builds the Docker image (if missing) and runs the container. Supports output flags (see below).

Questions answered when running (default, no flags):
1) Top homicide hotspots (address blocks) in the dataset and sample victims at those blocks.
2) Whether homicides with surveillance cameras have higher closure rates compared to those without.

New flags (added for Project 5 compatibility):
- `--output=csv` — write parsed records in CSV format.
- `--output=json` — write parsed records in JSON format.
- `--out-file=PATH` — when used with `--output`, write the output to `PATH`. Use `-` to stream to stdout.

Default filenames when `--out-file` is omitted:
- CSV: `homicides_2025.csv`
- JSON: `homicides_2025.json`

Examples
- Run default analysis (prints to stdout):
	```bash
	./run.sh
	```

- Write CSV to project directory (file will be created inside the container and, because `run.sh` mounts the project directory, it will appear on the host):
	```bash
	./run.sh --output=csv --out-file=homicides_2025.csv
	# result: project4/homicides_2025.csv
	```

- Stream CSV to stdout (useful for piping or CI):
	```bash
	./run.sh --output=csv --out-file=- | head -n 20
	```

- Example of running the container directly with an explicit bind-mount (equivalent to the run.sh behavior):
	```bash
	docker run --rm -v "$PWD":/app project4-baltimore:latest /usr/bin/sbt "run --output=csv --out-file=homicides_2025.csv"
	```

Notes
- The `--out-file=-` option streams selected format to stdout; piping into tools like `head` will stop the producer early (you may see a "broken pipe" message — this is normal).
- I tested Docker build and runs here: both `project4` and `project5` produce CSV and JSON outputs and the produced files appear under the respective project directories when using `--out-file=FILENAME`.

If you want a different default (for example, stream to stdout when `--output` is set but `--out-file` omitted), tell me and I can change the behavior.
