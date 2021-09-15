# data-infra

Welcome to the codebase for the Cal-ITP data warehouse and ETL pipeline.

Documentation for this codebase lives at [docs.calitp.org/data-infra](https://docs.calitp.org/data-infra/)

## Repository Structure

* `airflow` contains the local dev setup and source code for Airflow DAGs (ie, ETLs)
* `airflow/data/agencies.yml` contains catalogs for all transit agencies in CA's GTFS data.
* `ci` contains continious integration and deployment scripts using GH actions.
* `docs` builds the docs site.
* `kubernetes` contain helm charts, scripts and more for deploying apps and such on our kubernetes cluster.
* `script` contains associated scripts (mostly python) that are ad hoc.
* `services` contain apps that we write and deploy to kubernetes.

## Contributing

* Follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) standard for all commits
* Use Conventional Commit format for PR titles
* Use GitHub's *draft* status to indicate PRs that are not ready for review/merging
* Do not use GitHub's "update branch" button or merge the `main` branch back into a PR branch to update it. Instead, rebase PR branches to update them and resolve any merge conflicts.

## pre-commit

This repository uses black and pre-commit hooks to format code. To install locally, run

`pip install pre-commit` & `pre-commit install` in the root of the repo.
