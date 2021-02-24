# data-infra
temporary repo / maybe permanent for CalITP data infrastructure

## Repository Structure
* `airflow` contains the local dev setup and source code for Airflow DAGs (ie, ETLs)
* `airflow/dags` contains source code for ETLs, scripts, more.
* `catalogs` contains intake catalogs for semi-static / version data access.
* `jupyterhub` contains the image and commands for setting up ETLs to run

## pre-commit
This repository uses black and pre-commit hooks to format code. To install locally, run

`pip install pre-commit` & `pre-commit install` in the root of the repo.

## Running Locally
See `airflow/README.md`
