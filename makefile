VENV ?= .venv
VENV_BIN ?= $(VENV)/bin
PY   ?= $(VENV_BIN)/python
PIP  ?= $(VENV_BIN)/pip



venv:
	python3 -m venv $(VENV)
	$(PY) -m pip install --upgrade pip setuptools wheel

activate:
	@echo "To activate the virtualenv in your current shell run:"
	@echo "  source $(VENV)/bin/activate"

install-requirements: venv
	$(PIP) install -r requirements-dev.txt

clean-venv:
	rm -rf $(VENV)
	@echo "Removed $(VENV)" 

run-tests: check-matlab
	matlab -batch "runTests"

check-matlab:
	@command -v matlab >/dev/null 2>&1 || (echo "MATLAB not found in PATH. Please install MATLAB or add it to your PATH." && exit 1)

install-pre-commit:
	pre-commit install

clean-pre-commit:
	pre-commit uninstall

run-pre-commit:
	pre-commit run --all-files

install: install-requirements install-pre-commit

clean: clean-venv clean-pre-commit 

run-all: clean install run-pre-commit run-tests

run-checks: run-pre-commit run-tests
