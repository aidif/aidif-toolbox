VENV ?= .venv
VENV_BIN ?= $(VENV)/bin
PY   ?= $(VENV_BIN)/python
PIP  ?= $(VENV_BIN)/pip

.PHONY: venv install activate clean run-tests check-matlab pre-commit pre-commit-install pre-commit-checks
.PHONY: all

venv: activate
	python3 -m venv $(VENV)
	$(PY) -m pip install --upgrade pip setuptools wheel


activate:
	@echo "To activate the virtualenv in your current shell run:"
	@echo "  source $(VENV)/bin/activate"

install: venv
	$(PIP) install -r requirements-dev.txt

clean:
	rm -rf $(VENV)
	@echo "Removed $(VENV)"

run-tests: check-matlab
	matlab -batch "runTests"

check-matlab:
	@command -v matlab >/dev/null 2>&1 || (echo "MATLAB not found in PATH. Please install MATLAB or add it to your PATH." && exit 1)
	@echo "MATLAB found at: $$(command -v matlab)"

pre-commit-install:
	pre-commit install
	@echo "Pre-commit hooks installed."

pre-commit: pre-commit-install
	pre-commit run --all-files
	@echo "Pre-commit checks complete."

all: clean install pre-commit run-tests
