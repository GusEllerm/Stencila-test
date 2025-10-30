# Stencila .smd Compiler (Makefile CLI)

A tiny CLI powered by `make` that compiles a Stencila `.smd` template into an evaluated micropublication HTML, following this pipeline:

1) `stencila convert` template.smd → `build/DNF.json`
2) `stencila render` DNF.json → `build/DNF_eval.json` (`--force-all --pretty`)
3) `stencila convert` DNF_eval.json → `build/micropublication.html` (`--pretty`)

Python packages needed during evaluation (e.g., `pandas`, `rocrate`) are installed into an isolated virtual environment under `build/.venv` automatically.

## Requirements

- Python 3.8+ (for the virtual environment)
- Node.js 18+ (so we can run Stencila via `stencila` or `npx @stencila/cli`)
- A `.smd` template (e.g., `test_DNF.smd`) and a `data.json` file in the project root

Install the Stencila CLI (recommended):

```zsh
curl -LsSf https://stencila.io/install.sh | bash
```

Or use the helper target:

```zsh
make stencila-install
```

## Quick start

1) Ensure you have your `.smd` template and matching `data.json` in this folder.
2) Run the compile pipeline:

```zsh
make compile
```

The final output will be at:

- `build/micropublication.html`

## Commands

- `make help` — Show usage and detected settings
- `make compile` — Run the full pipeline (creates venv, installs Python deps if needed)
- `make setup` — Create `build/.venv` and install `pandas` + `rocrate`
- `make init-data` — Create a stub `data.json` if missing
- `make clean` — Remove the `build/` directory
- `make stencila-install` — Install the Stencila CLI via the official script

## Options (variables)

You can override variables on the command line:

- `SMD` — Path to the `.smd` template. Defaults to the first `*.smd` in the folder.
- `DATA` — Path to the data file. Defaults to `data.json`.
- `BUILD_DIR` — Output directory. Defaults to `build`.

Examples:

```zsh
# Compile a specific template
make compile SMD=test_DNF.smd

# Use a different data file and output directory
make compile SMD=paper.smd DATA=inputs/data.json BUILD_DIR=out
```

## Outputs

- `${BUILD_DIR}/DNF.json` — Converted DNF document
- `${BUILD_DIR}/DNF_eval.json` — Evaluated DNF document
- `${BUILD_DIR}/micropublication.html` — Final HTML

## Troubleshooting

- Error: `data.json not found` — Create it or run:
  ```zsh
  make init-data
  ```
- Error: `No .smd file found` — Specify the template:
  ```zsh
  make compile SMD=my_template.smd
  ```
- Error: `stencila CLI not found` — Install the CLI:
  ```zsh
  curl -LsSf https://stencila.io/install.sh | bash
  # or
  make stencila-install
  ```
- To reset the Python environment (if dependencies get into a bad state):
  ```zsh
  rm -rf build/.venv
  make setup
  ```

## Notes

- The Makefile prepends the venv `bin` directory to `PATH` when running Stencila so that any Python code called during evaluation uses the isolated environment.
- Default goal is `help`, so running `make` with no target shows basic usage.
