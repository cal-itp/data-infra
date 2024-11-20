#!/usr/bin/env bash
set -u

# workaround VS Code devcontainer .git mounting issue
git config --global --add safe.directory /home/calitp/app

# initialize hook environments
pre-commit install --install-hooks --overwrite

cd warehouse/

if [ ! -f ~/.dbt/profiles.yml ]; then
    poetry run dbt init
fi

poetry run dbt debug

if [[ $? != 0 ]]; then
    gcloud init
    gcloud auth application-default login
fi
