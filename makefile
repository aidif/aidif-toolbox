VENV ?= .venv
VENV_BIN ?= $(VENV)/bin
PY   ?= $(VENV_BIN)/python
PIP  ?= $(VENV_BIN)/pip

.PHONY: venv install activate clean run-tests check-matlab install-requirements clean-venv install-pre-commit clean-pre-commit run-pre-commit install run-checks

venv:
	python3 -m venv $(VENV)
	$(PY) -m pip install --upgrade pip setuptools wheel
	bash -c "source $(VENV)/bin/activate"

check-venv:
	@command -v $(PY) >/dev/null 2>&1 || (echo "Python not found in virtual environment. Please create the virtual environment." && exit 1)

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

init: venv activate

install: venv install-requirements install-pre-commit

clean: clean-pre-commit clean-venv 

run: run-pre-commit run-tests

validate-setup: check-venv check-matlab

help:
	@echo "Makefile Help:"
	@echo "Available targets:"
	@echo "  init - Initialize the development environment"
	@echo "  install - Install dependencies and pre-commit hooks"
	@echo "  run - Run pre-commit checks and tests"
	@echo "  validate-setup - validate the setup of the environment"
	@echo "  clean - Clean the virtual environment and pre-commit hooks"
	@echo ""
	@echo "Usage:"
	@echo "  make [target]"
	@echo "Example:"
	@echo "  make run-checks"
