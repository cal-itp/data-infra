# GitHub Actions

All CI/CD automation in this project is executed via GitHub Actions, whose workflow files live in this directory.

Some of these workflows use hologit or invoke. See the READMEs in [.holo](../../.holo) and [ci](../../ci) for documentation regarding hologit and invoke, respectively.


### build-\*.yml workflows

Workflows prefixed with `build-` generally lint, test, and (usually) publish either a Python package or a Docker image.


### preview-\*.yml workflows

Workflows prefixed with `preview-` deal with generating previews for pull request changes.


## composer-plan-files.yml

When creating a PR that changes any file in the `airflow` directory, this workflow runs `Terraform plan` to create a comment with an execution plan to preview the changes that will be made to Production and Staging Airflow DAGs.


## composer-apply-files.yml

When merging a PR into the `main` branch with changes to any file in the `airflow` directory, this workflow runs `Terraform apply` to execute the actions proposed in the `Terraform plan` to Production and Staging Airflow DAGs.

This workflow replaced `deploy-airflow` and `deploy-airflow-requirements`.

The GCP Composer deployment of Airflow [uploads composer, warehouse, and dbt artifact files](https://github.com/cal-itp/data-infra/blob/main/iac/cal-itp-data-infra/airflow/us/storage_bucket_object.tf) to a [GCS bucket](https://github.com/cal-itp/data-infra/blob/9a7d83b32018ebbebde07227c8241042418e62f6/iac/cal-itp-data-infra/composer/us/environment.tf#L7) that Composer reads.


  * Composer files: all `.py`, `.yml`, and `.md` files from `airflow/dags/` folder.

  * Warehouse files: `dbt_project.yml`, `packages.yml`, `profiles.yml`, and all files from `macros/`, `models/`, `seeds/`, and `tests/` folders.

  * dbt artifact files: `manifest.json`, `catalog.json`, and `index.html`.


  For more details, check [iac/cal-itp-data-infra/airflow/us/variables.tf](https://github.com/cal-itp/data-infra/blob/main/iac/cal-itp-data-infra/airflow/us/variables.tf).


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
