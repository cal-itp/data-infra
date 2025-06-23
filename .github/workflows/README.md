# GitHub Actions

All CI/CD automation in this project is executed via GitHub Actions, whose workflow files live in this directory.

Some of these workflows use hologit or invoke. See the READMEs in [.holo](../../.holo) and [ci](../../ci) for documentation regarding hologit and invoke, respectively.


### build-\*.yml workflows

Workflows prefixed with `build-` generally lint, test, and (usually) publish either a Python package or a Docker image.


### preview-\*.yml workflows

Workflows prefixed with `preview-` deal with generating previews for pull request changes.


## composer-plan-files.yml

When creating a PR that changes any file in the `airflow` directory, this workflow runs `Terraform plan` to create a comment with an execution plan to preview the changes that will be made to Staging Airflow DAGs.


## composer-apply-files.yml

When merging a PR into the `main` branch with changes to any file in the `airflow` directory, this workflow runs `Terraform apply` to execute the actions proposed in the `Terraform plan` to Staging Airflow DAGs.


## deploy-airflow.yml

While we're using GCP Composer, "deployment" of Airflow consists of two parts:

1. Calling `gcloud composer environments update ...` to update the Composer environment with new (or specific versions of) packages
2. Copying the `dags` and `plugins` folders to a GCS bucket that Composer reads (this is specified in the Composer Environment)


## deploy-airflow-requirements.yml

When merging `airflow/requirements.txt` changes into the `main` branch, this workflow updates composer dependencies.


## deploy-apps-maps.yml

This workflow builds a static website from the Svelte app and deploys it to Netlify.


## deploy-dbt.yml

This workflow compiles dbt models and docs, syncs Metabase, uploads dbt artifacts, builds a visual comment about model changes.


## deploy-kubernetes.yml

This workflow deploys changes to the production Kubernetes cluster when they get merged into the `main` branch.


## preview-kubernetes.yml

This workflow renders kubectl diffs on PRs changing cluster content.


## publish-docs.yml

This workflow builds jupyter book docs and publishes docs to GitHub Pages.


## sentry-release.yml

When merging any changes into the `main` branch, this workflow notify the release to Sentry.


## terraform-plan.yml

When creating a PR that changes any file in the `iac` directory (Infrastructure as Code), this workflow runs `Terraform plan` to create a comment with an execution plan to preview the changes that will be made to the infrastructure.


## terraform-apply.yml

When merging a PR into the `main` branch with changes to any file in the `iac` directory (Infrastructure as Code), this workflow runs `Terraform apply` to execute the actions proposed in the `Terraform plan` to the infrastructure.
