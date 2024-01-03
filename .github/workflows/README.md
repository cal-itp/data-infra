# GitHub Actions

All CI/CD automation in this project is executed via GitHub Actions, whose workflow files live in this directory.

## deploy-airflow.yml

While we're using GCP Composer, "deployment" of Airflow consists of two parts:

1. Calling `gcloud composer environments update ...` to update the Composer environment with new (or specific versions of) packages
2. Copying the `dags` and `plugins` folders to a GCS bucket that Composer reads (this is specified in the Composer Environment)

## deploy-apps-maps.yml

This workflow builds a static website from the Svelte app and deploys it to Netlify.

## build-\*.yml workflows

Workflows prefixed with `build-` generally lint, test, and (usually) publish either a Python package or a Docker image.

## service-\*.yml workflows

Workflows prefixed with `service-` deal with Kubernetes deployments.

- `service-release-candidate.yml` creates candidate branches, using [hologit](https://github.com/JarvusInnovations/hologit) to bring in external Helm charts and remove irrelevant (i.e. non-infra) code
- `service-release-diff.yml` renders kubectl diffs on PRs targeting release branches
- `service-release-channel.yml` deploys to a given channel (i.e. environment) on updates to a release branch

Some of these workflows use hologit or invoke. See the READMEs in [.holo](../../.holo) and [ci](../../ci) for documentation regarding hologit and invoke, respectively.
