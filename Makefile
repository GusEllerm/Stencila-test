# Generic Makefile to compile an .smd document using Stencila
# Pipeline:
#   1) stencila convert <template.smd> -> build/DNF.json
#   2) stencila render  build/DNF.json -> build/DNF_eval.json  (--force-all --pretty)
#   3) stencila convert build/DNF_eval.json -> build/micropublication.html (--pretty)
#
# It also prepares a Python virtualenv and installs packages used during evaluation.

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# ---------- Configurable variables ----------
# First .smd in the folder by default; override via `make compile SMD=foo.smd`
SMD ?= $(firstword $(wildcard *.smd))
# The data file expected by the template
DATA ?= data.json
# Build artifacts directory
BUILD_DIR ?= build
# Python & virtual environment
PY ?= python3
VENV ?= $(BUILD_DIR)/.venv
PIP := $(VENV)/bin/pip
PYTHON := $(VENV)/bin/python

# Output files
DNF_JSON := $(BUILD_DIR)/DNF.json
DNF_EVAL := $(BUILD_DIR)/DNF_eval.json
MICROPUB := $(BUILD_DIR)/micropublication.html

# Detect Stencila CLI (installed binary), searching common locations if not on PATH
STENCILA_PATH := $(shell \
	(command -v stencila 2>/dev/null) || \
	([ -x /usr/local/bin/stencila ] && echo /usr/local/bin/stencila) || \
	([ -x $(HOME)/.local/bin/stencila ] && echo $(HOME)/.local/bin/stencila) || \
	([ -x /opt/homebrew/bin/stencila ] && echo /opt/homebrew/bin/stencila) \
)
STENCILA_CMD := $(STENCILA_PATH)

.DEFAULT_GOAL := help

# ---------- Phony targets ----------
.PHONY: help compile setup check clean init-data stencila-install

help:
	@echo "Usage:"
	@echo "  make compile [SMD=<file.smd>] [DATA=data.json] [BUILD_DIR=build]"
	@echo ""
	@echo "Targets:"
	@echo "  compile    Run the full pipeline to produce $(MICROPUB)"
	@echo "  setup      Create venv and install Python deps (pandas, rocrate)"
	@echo "  init-data  Create a stub data.json if it does not exist"
	@echo "  clean      Remove build artifacts"
	@echo "  stencila-install  Install the Stencila CLI (macOS/Linux) via official script"
	@echo ""
	@echo "Detected Stencila command: $(if $(STENCILA_CMD),$(STENCILA_CMD),(none found))"
	@echo "Detected SMD: $(if $(SMD),$(SMD),(none found))"
	@echo ""
	@echo "If 'stencila' is installed but not detected, add its dir to PATH, e.g.:"
	@echo "  export PATH=\"/usr/local/bin:$$PATH\"   # or /opt/homebrew/bin on macOS ARM"

# Ensure venv exists and core packages are installed
setup: $(VENV)/.ready

$(VENV)/.ready:
	@echo "🔧 Setting up Python virtual environment at $(VENV)"
	@mkdir -p $(BUILD_DIR)
	@if [ ! -d "$(VENV)" ]; then $(PY) -m venv "$(VENV)"; fi
	@$(PIP) install --upgrade pip wheel >/dev/null
	@echo "📦 Installing Python packages: pandas rocrate"
	@$(PIP) install --quiet pandas rocrate >/dev/null
	@touch $@

# Basic validations mirroring the reference logic
check:
	@if [ -z "$(SMD)" ]; then echo "Error: No .smd file found. Specify with SMD=<file.smd>"; exit 1; fi
	@if [ ! -f "$(SMD)" ]; then echo "Error: SMD file '$(SMD)' not found"; exit 1; fi
	@if [ ! -f "$(DATA)" ]; then echo "Error: Required data file '$(DATA)' not found"; exit 1; fi
	@if [ -z "$(STENCILA_CMD)" ]; then \
	  echo "Error: 'stencila' CLI not found on PATH."; \
	  echo "Install it (macOS/Linux):"; \
	  echo "  curl -LsSf https://stencila.io/install.sh | bash"; \
	  echo "or run: make stencila-install"; \
	  echo "If already installed, ensure its directory is on PATH (e.g. /usr/local/bin or /opt/homebrew/bin)."; \
	  echo "Docs: https://github.com/stencila/stencila#install"; \
	  exit 1; \
	fi

# Create a stub data.json if missing
init-data:
	@if [ -f "$(DATA)" ]; then echo "$(DATA) already exists"; else echo '{}' > "$(DATA)" && echo "Created stub $(DATA)"; fi

# Main pipeline
compile: check setup $(MICROPUB)
	@echo "✅ Done: $(MICROPUB)"

$(DNF_JSON): $(SMD) | $(BUILD_DIR)
	@echo "🧪 Running Stencila pipeline: convert -> DNF.json"
	# Prepend venv bin to PATH so Stencila uses the venv Python
	PATH="$(VENV)/bin:$$PATH" $(STENCILA_CMD) convert "$(SMD)" "$@"

$(DNF_EVAL): $(DNF_JSON)
	@echo "🔬 Evaluating DNF: render -> DNF_eval.json"
	PATH="$(VENV)/bin:$$PATH" $(STENCILA_CMD) render "$(DNF_JSON)" "$@" --force-all --pretty

$(MICROPUB): $(DNF_EVAL)
	@echo "🖨️  Producing final HTML: convert -> micropublication.html"
	PATH="$(VENV)/bin:$$PATH" $(STENCILA_CMD) convert "$(DNF_EVAL)" "$@" --pretty

$(BUILD_DIR):
	@mkdir -p "$(BUILD_DIR)"

clean:
	@echo "🧹 Cleaning build artifacts"
	@rm -rf "$(BUILD_DIR)"

# Convenience target to install Stencila CLI (macOS/Linux)
stencila-install:
	@echo "📥 Installing Stencila CLI (may prompt for sudo if installing to /usr/local/bin)"
	curl -LsSf https://stencila.io/install.sh | bash
