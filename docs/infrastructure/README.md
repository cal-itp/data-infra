# Infrastructure code

# pyinvoke

[invoke](https://docs.pyinvoke.org/en/stable/) is a Python framework for executing subprocess and building a CLI application.
The tasks are defined in `tasks.py` and configuration in `invoke.yaml`; config values under the top-level `calitp`
are specific to our defined tasks.

Run `poetry run invoke -l` to list the available commands, and `poetry run invoke -h <command>` to get more detailed help for each individual command.

## CI/CD

All CI/CD automation in this project is executed via GitHub Actions, whose workflow files .

## deploy-airflow.yml

While we're using GCP Composer, "deployment" of Airflow consists of two parts:

1. Calling `gcloud composer environments update ...` to update the Composer environment with new (or specific versions of) packages
2. Copying the [dags](../../airflow/dags) and [plugins](../../airflow/plugins) folders to a GCS bucket that Composer reads

## build-*.yml workflows

Workflows prefixed with `build-` generally lint, test, and (usually) publish either a Python package or a Docker image.

## service-*.yml workflows

Workflows prefixed with `service-` deal with Kubernetes deployments.

* `service-release-candidate.yml` creates candidate branches, using hologit to bring in external Helm charts and remove irrelevant (i.e. non-infra) code
* `service-release-diff.yml` renders kubectl diffs on PRs targeting release branches
* `service-release-channel.yml` deploys to a given channel (i.e. environment) on updates to a release branch

Some of these workflows use the same `invoke` framework described earlier.
