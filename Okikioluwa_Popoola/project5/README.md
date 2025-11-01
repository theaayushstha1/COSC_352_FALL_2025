# Project 5 Data Formats

The Project 5 Scala application now produces the same homicide research answers in three formats so that downstream tooling can ingest them consistently.

## Text (default)
- Triggered when no `--output` flag is provided or when the value is `stdout`/`text`.
- Printed questions and answers mirror the original console output.

## CSV (`baltimore_homicide_answers.csv`)
- Generated when `--output=csv` is passed to `run.sh`.
- Two columns: `question`, `answer`.
- CSV values are UTF-8 encoded and RFC 4180 compliant (quotes doubled, fields wrapped when needed).
- Suitable for spreadsheet import or simple SQL bulk loads.

Example:
```
question,answer
"How old is Richie Briggs?","Richie Briggs was 29 years old."
"Where does Edward Johnson live?","Edward Johnson lived at: 123 Example St, Baltimore City."
```

## JSON (`baltimore_homicide_answers.json`)
- Generated when `--output=json` is passed.
- UTF-8 encoded array of objects with `question` and `answer` string fields.
- Escapes common control characters so the payload is ready for downstream APIs.

Example:
```json
[
  {"question": "How old is Richie Briggs?", "answer": "Richie Briggs was 29 years old."},
  {"question": "Where does Edward Johnson live?", "answer": "Edward Johnson lived at: 123 Example St, Baltimore City."}
]
```

Both structured formats use the question text as the primary key, which keeps the data stable even if lookup indices change on the source site. Downstream consumers can join on the `question` column/field or simply read the array in order.
