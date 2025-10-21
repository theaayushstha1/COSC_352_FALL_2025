# Table to CSV Docker Container

This Docker container extracts HTML tables from web pages or local HTML files and converts them to CSV format.

## Building the Docker Image

```bash
docker build -t table2csv .
```

## Running the Container

### Extract tables from a URL:
```bash
docker run --rm -v $(pwd)/output:/app/output table2csv "https://example.com/page-with-tables"
```

### Extract tables from a local HTML file:
```bash
docker run --rm -v $(pwd):/app/input -v $(pwd)/output:/app/output table2csv "/app/input/your-file.html"
```

### Specify custom output directory:
```bash
docker run --rm -v $(pwd)/my-output:/app/output table2csv "https://example.com" "/app/output"
```

## Windows PowerShell Commands

If you're using Windows PowerShell, use `${PWD}` instead of `$(pwd)`:

```powershell
# Extract from URL
docker run --rm -v ${PWD}/output:/app/output table2csv "https://example.com/page-with-tables"

# Extract from local file
docker run --rm -v ${PWD}:/app/input -v ${PWD}/output:/app/output table2csv "/app/input/your-file.html"
```

## Output

- CSV files will be created in the `output/` directory
- Files are named `table_1.csv`, `table_2.csv`, etc.
- Each table from the HTML source gets its own CSV file

## Examples

```bash
# Scrape tables from Wikipedia
docker run --rm -v $(pwd)/output:/app/output table2csv "https://en.wikipedia.org/wiki/List_of_countries_by_population"

# Process local HTML file
docker run --rm -v $(pwd):/app/input -v $(pwd)/output:/app/output table2csv "/app/input/data.html"
```

## Volume Mounts Explained

- `-v $(pwd)/output:/app/output` - Mounts your local `output` folder to the container's `/app/output`
- `-v $(pwd):/app/input` - Mounts your current directory as `/app/input` for reading local files
- `--rm` - Automatically removes the container when it exits

## Troubleshooting

If you get permission errors, ensure the output directory exists:
```bash
mkdir -p output
```