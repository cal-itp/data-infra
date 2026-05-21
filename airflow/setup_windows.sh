#!/usr/bin/env bash
# Windows (git-bash) setup script for Airflow local development
# Assumes: git-bash, Rancher Desktop, gcloud CLI, Python 3.11

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Setting up Airflow local development on Windows ==="

# --- Path Setup ---
export USER=$(whoami)
export PATH="$HOME/bin:$PATH"
export PATH="$PATH:/c/Users/$USER/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin"
UV_SCRIPTS="/c/Users/$USER/AppData/Local/Packages/PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0/LocalCache/local-packages/Python313/Scripts"
export PATH="$PATH:$UV_SCRIPTS"
export CLOUDSDK_PYTHON="/c/Users/$USER/AppData/Local/Microsoft/WindowsApps/python.exe"
export PYTHONIOENCODING=utf-8

# Find Python 3.11
PY311="C:/Users/$USER/AppData/Local/Programs/Python/Python311/python.exe"
if [ -f "$PY311" ]; then
    export UV_PYTHON="$PY311"
    echo "Using Python 3.11: $PY311"
else
    echo "WARNING: Python 3.11 not found at $PY311"
    echo "Install from https://www.python.org/downloads/"
fi

# --- Tool Check ---
echo ""
echo "=== Checking prerequisites ==="
echo "Docker: $(docker --version 2>/dev/null || echo 'NOT FOUND')"
echo "make:   $(make --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
echo "rsync:  $(rsync --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
echo "uv:     $(uv --version 2>/dev/null || echo 'NOT FOUND')"
echo "gcloud: $(gcloud --version 2>/dev/null | head -1 || echo 'NOT FOUND')"

if ! command -v make &>/dev/null; then
    echo "ERROR: make is required. Install via MSYS2:"
    echo "  curl -sL https://repo.msys2.org/msys/x86_64/make-4.4.1-2-x86_64.pkg.tar.zst -o /tmp/make.pkg.tar.zst"
    echo "  Then extract and copy make.exe to ~/bin/"
    exit 1
fi

# --- Warehouse Setup ---
echo ""
echo "=== Setting up warehouse (dbt deps + compile) ==="
cd "$PROJECT_ROOT/warehouse"

# Check if uv sync works (it may fail on pygraphviz on Windows)
if uv sync --no-group dev 2>/dev/null; then
    echo "uv sync succeeded"
else
    echo "uv sync failed (likely pygraphviz build issue). Using pip fallback..."
    pip install dbt-core dbt-bigquery 2>/dev/null || python -m pip install dbt-core dbt-bigquery
fi

uv run dbt deps || true
uv run dbt compile --target staging || true

# --- Airflow Setup ---
echo ""
echo "=== Setting up airflow ==="
cd "$SCRIPT_DIR"

if [ ! -d ".venv" ]; then
    uv sync
else
    echo "Airflow venv already exists"
fi

# Setup composer environment
if [ ! -d "composer/calitp-development-composer" ]; then
    make setup
else
    echo "Composer environment already exists"
fi

# Sync files
make sync

# Fix Windows-specific env var
echo "COMPOSER_CONTAINER_RUN_AS_HOST_USER=False" >> composer/calitp-development-composer/variables.env 2>/dev/null || true

echo ""
echo "=== Setup complete ==="
echo ""
echo "To start Airflow:"
echo "  cd airflow"
echo "  export PYTHONIOENCODING=utf-8"
echo "  .venv/Scripts/composer-dev.exe start"
echo ""
echo "Airflow UI: http://localhost:8080"
