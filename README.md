# data-infra

Welcome to the codebase for the Cal-ITP data warehouse and ETL pipeline.

Documentation for this codebase lives at [docs.calitp.org/data-infra](https://docs.calitp.org/data-infra/)

## Repository Structure

- [./airflow](./airflow) contains the local dev setup and source code for Airflow DAGs (i.e. E# data-infra

Welcome to the codebase for the Cal-ITP data warehouse and ETL pipeline.

Documentation for this codebase lives at [docs.calitp.org/data-infra](https://docs.calitp.org/data-infra/)

## Repository Structure

- [./airflow](./airflow) contains the local dev setup and source code for Airflow DAGs (i.e. ETL).
- [./ci](./ci) contains continuous integration and deployment scripts using GitHub Actions.
- [./docs](./docs) builds the [docs site](https://docs.calitp.org/data-infra).
- [./kubernetes](./kubernetes) contains helm charts, scripts and more for deploying apps/services (e.g. Metabase, JupyterHub) on our kubernetes cluster.
- [./images](./images) contains images we build and deploy for use by services such as JupyterHub.
- [./services](./services) contains apps that we write and deploy to kubernetes.
- [./warehouse](./warehouse) contains our dbt project that builds and tests models in the BigQuery warehouse.

## Development environment with VS-Code and devcontainer

### Prerequisites

1. **Visual Studio Code** – latest stable release.
2. **Remote Containers (Dev Containers) extension** – install from the VS Code Marketplace.
3. **Docker Engine**
    - Docker Desktop (Windows/macOS) **or** Docker Engine (Linux) **or** Rancher Desktop for Caltrans Laptop.
    - Ensure Docker is running and the current user has permission to run `docker` commands.
5. (Optional) **GitHub authentication** – sign in to GitHub from VS Code (Accounts pane) so that `git push` works without configuring SSH keys or a personal access token.

### Getting started

1. **Open VS Code**.
2. **Install the Remote Containers extension** if you haven’t already (`Ctrl+Shift+X` → search “Remote Containers”).
3. From the Command Palette (`Ctrl+Shift+P`) run **`Remote‑Containers: Clone Repository in Container Volume…`** or you prefer to specify a named volume **`Remote‑Containers: Clone Repository in Named Container Volume…`**.
    - Paste the repository URL: `https://github.com/cal-itp/data-infra`.
    - VS Code will create a Docker volume, pull the base image `mcr.microsoft.com/devcontainers/base:bookworm`, and clone the repo **directly into the volume** (`/workspaces/data-infra`).
4. Once the clone finishes, VS Code automatically starts the **devcontainer** defined in `.devcontainer/devcontainer.json`.
    - The volume is mounted at `/workspaces/data-infra` inside the container, which becomes the workspace root.
    - All tools (Nix, Direnv, Docker‑in‑Docker, etc.) are pre‑installed via the devcontainer features.
    - **First‑time shell start:** The initial shell launch may be slow while Nix builds the development environment for the first time.
    - **VS Code extensions:** Extensions such as **Direnv** and **Better TOML** are not pre‑installed in the devcontainer; install them        manually via the VS Code Extensions pane.

5. **Develop**
    - Use the VS Code UI or an integrated terminal (`Ctrl+` ``) to edit code, run tests, or start services.
    - Git operations work out‑of‑the‑box; if you signed in to GitHub via the VS Code *Accounts* pane, `git push` will use the built‑in credential helper.
6. **Stop / Re‑open**
    - When you close the container, the Docker volume persists. Re‑opening the folder (`Remote‑Containers: Reopen in Container`) will reuse the same volume, giving you a fast start‑up with the existing checkout.

## Contributing

### Pre-commit

This repository uses pre-commit hooks to format code, including [Black](https://black.readthedocs.io/en/stable/index.html). This ensures baseline consistency in code formatting.

> [!IMPORTANT]
> Before contributing to this project, please install pre-commit locally by running `pip install pre-commit` and `pre-commit install` in the root of the repo.

Once installed, pre-commit checks will run before you can make commits locally. If a pre-commit check fails, it will need to be addressed before you can make your commit. Many formatting issues are fixed automatically within the pre-commit actions, so check the changes made by pre-commit on failure -- they may have automatically addressed the issues that caused the failure, in which case you can simply re-add the files, re-attempt the commit, and the checks will then succeed.

Installing pre-commit locally saves time dealing with formatting issues on pull requests. There is a [GitHub Action](./.github/workflows/lint.yml)
that runs pre-commit on all files, not just changed ones, as part of our continuous integration.

> [!NOTE]
> [SQLFluff](https://sqlfluff.com/) is currently disabled in the CI run due to flakiness, but it will still lint any SQL files you attempt to commit locally. You will need to manually correct SQLFluff errors because we found that SQLFluff's automated fixes could be too aggressive and could change the meaning and function of affected code.

### Pull requests

- Use GitHub's *draft* status to indicate PRs that are not ready for review/merging
- Do not use GitHub's "update branch" button or merge the `main` branch back into a PR branch to update it. Instead, rebase PR branches to update them and resolve any merge conflicts.
- We use GitHub's "code owners" functionality to designate a person or group of people who are in the line of approval for changes to some parts of this repository - if one or more people are automatically tagged as reviewers by GitHub when you create a PR, an approving review from at least one of them is required to merge. This does not automatically place the PR review in somebody's list of priorities, so please reach out to a reviewer to get eyes on your PR if it's time-sensitive.

### mypy

We encourage mypy compliance for Python when possible, though we do not
currently run mypy on Airflow DAGs. All service and job images do pass mypy,
which runs in the GitHub Actions that build the individual images. If you are
unfamiliar with Python type hints or mypy, the following documentation links
will prove useful.

- [PEP 484](https://peps.python.org/pep-0484/), which added type hints
- [The typing module docs](https://docs.python.org/3/library/typing.html)
- [The mypy docs](https://mypy.readthedocs.io/en/stable/)

In general, it should be relatively easy to make most of our code pass mypy
since we make heavy use of Pydantic types. Some of our imported modules will
need to be ignored with `# type: ignore` on import, such as `gcsfs`
and `shapely` (until stubs are available, if ever). We recommend including
comments where additional asserts or other weird-looking code exist to make mypy
happy.

### Configuration via Environment Variables

Generally we try to configure things via environment variables. In the Kubernetes
world, these get configured via Kustomize overlays ([example](./kubernetes/apps/overlays/gtfs-rt-archiver-v3-prod/archiver-channel-vars.yaml)).
For Airflow jobs, we currently use hosted Google Cloud Composer which has a
[user interface](https://console.cloud.google/composer/environments/detail/us-west2/calitp-composer/variables?project=cal-itp-data-infra)
for editing environment variables. These environment variables also have to be
injected into pod operators as needed via Gusty YAML or similar. If you are
running Airflow locally, the [docker compose file](./airflow/docker-compose.yaml)
needs to contain appropriately set environment variables.
