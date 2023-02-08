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
* We use GitHub's "code owners" functionality to designate a person or group of people who are in the line of approval for changes to some parts of this repository - if one or more people are automatically tagged as reviewers by GitHub when you create a PR, an approving review from at least one of them is required to merge. This does not automatically place the PR review in somebody's list of priorities, so please reach out to a reviewer to get eyes on your PR if it's time-sensitive.

## Linting and type-checking

### pre-commit

This repository pre-commit hooks to format code, including black. To install
pre-commit locally, run `pip install pre-commit` & `pre-commit install`
in the root of the repo. There is a [GitHub Action](./github/workflows/lint.yml)
that runs pre-commit on all files, not just changed ones. sqlfluff is currently
disabled in the CI run due to flakiness, but it will still lint any SQL files
you attempt to commit locally.

### mypy

We encourage mypy compliance for Python when possible, though we do not
currently run mypy on Airflow DAGs. All service and job images do pass mypy,
which runs in the GitHub Actions that build the individual images. If you are
unfamiliar with Python type hints or mypy, the following documentation links
will prove useful.

* [PEP 484](https://peps.python.org/pep-0484/), which added type hints
* [The typing module docs](https://docs.python.org/3/library/typing.html)
* [The mypy docs](https://mypy.readthedocs.io/en/stable/)

In general, it should be relatively easy to make most of our code pass mypy
since we make heavy use of Pydantic types. Some of our imported modules will
need to be ignored with `# type: ignore` on import, such as `gcsfs`
and `shapely` (until stubs are available, if ever). We recommend including
comments where additional asserts or other weird-looking code exist to make mypy
happy.

## Configuration via Environment Variables

Generally we try to configure things via environment variables. In the Kubernetes
world, these get configured via Kustomize overlays ([example](./kubernetes/apps/overlays/gtfs-rt-archiver-v3-prod/archiver-channel-vars.yaml)).
For Airflow jobs, we currently use hosted Google Cloud Composer which has a
[user interface](https://console.cloud.google.com/composer/environments/detail/us-west2/calitp-airflow2-prod/variables)
for editing environment variables. These environment variables also have to be
injected into pod operators as needed via Gusty YAML or similar. If you are
running Airflow locally, the [docker-compose file](./airflow/docker-compose.yaml)
needs to contain appropriately set environment variables.
