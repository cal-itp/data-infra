# GitHub Actions

All CI/CD automation in this project is executed via GitHub Actions, whose workflow files live in this directory.

Some of these workflows use hologit or invoke. See the READMEs in [.holo](../../.holo) and [ci](../../ci) for documentation regarding hologit and invoke, respectively.

### build-\*.yml workflows

Workflows prefixed with `build-` generally lint, test, and (usually) publish either a Python package or a Docker image.

### preview-\*.yml workflows

Workflows prefixed with `preview-` deal with generating previews for pull request changes.

### Staging and production branches

Production deploys from `main`. Staging code (Airflow, Composer, dbt, the GTFS-RT archiver) deploys only from `staging/official`, which always equals `main` plus the changes being tested; staging infrastructure in `iac/` applies from `main`. See [Staging Deployment](../../docs/architecture/staging-deployment.md) for the full workflow.

Deploy workflows compute their changed files with the [changed-files](../actions/changed-files/action.yml) action instead of a `paths` filter, because `staging/official` gets force-pushed when a test is dropped.

## build-model-report.yml

This workflow compiles dbt, posts a comment on PRs listing exposures impacted by the changed models, and uploads the latest staging dbt artifacts, which staging Airflow reads, when `staging/official` changes.

## composer-plan-files.yml

> [!NOTE]
> This workflow creates plans to show DAG changes.
> If there are also changes to `iac/.../airflow/` or `iac/.../composer/` files, only the [terraform-plan.yml](#terraform-plan.yml) workflow will create the plan.

When creating a PR that changes any file in the `airflow` directory, this workflow runs `Terraform plan` to create a comment with an execution plan to preview the changes that will be made to Production and Staging Airflow DAGs.

- PRs into `main`: production plans, and staging plans computed on `staging/official` with the PR merged in (what the sync will deploy after merging).
- PRs into `staging/official`: staging plans only.

## composer-apply-files.yml

> [!NOTE]
> This workflow applies DAG changes.
> If there are also changes to `iac/.../airflow/` or `iac/.../composer/` files, only the [terraform-apply.yml](#terraform-apply.yml) workflow will execute the plan.

When changes to any file in the `airflow` directory are pushed, this workflow runs `Terraform apply`: to Production Airflow on pushes to `main`, and to Staging Airflow on pushes to `staging/official` (auto-approved, since syncs and rebuilds have no PR plan).

This workflow replaced `deploy-airflow` and `deploy-airflow-requirements`.

The GCP Composer deployment of Airflow [uploads composer, warehouse, and dbt artifact files](https://github.com/cal-itp/data-infra/blob/main/iac/cal-itp-data-infra/airflow/us/storage_bucket_object.tf) to a [GCS bucket](https://github.com/cal-itp/data-infra/blob/9a7d83b32018ebbebde07227c8241042418e62f6/iac/cal-itp-data-infra/composer/us/environment.tf#L7) that Composer reads.

* Composer files: all `.py`, `.yml`, and `.md` files from `airflow/dags/` folder.

* Warehouse files: `dbt_project.yml`, `packages.yml`, `profiles.yml`, and all files from `macros/`, `models/`, `seeds/`, and `tests/` folders.

* dbt artifact files: `manifest.json`, `catalog.json`, and `index.html`.

  For more details, check [iac/cal-itp-data-infra/airflow/us/variables.tf](https://github.com/cal-itp/data-infra/blob/main/iac/cal-itp-data-infra/airflow/us/variables.tf).

## deploy-apps-maps.yml

This workflow builds a static website from the Svelte app and deploys it to Netlify.

## deploy-dbt.yml

> [!NOTE]
> This workflow applies Warehouse (dbt models and dbt artifacts) changes.
> If there are also changes to `iac/.../airflow/` files, only the [terraform-apply.yml](#terraform-apply.yml) workflow will execute the plan.

This workflow compiles dbt models and docs, runs changed models, syncs Metabase, and uploads dbt artifacts to update [dbt docs site](https://dbt-docs.dds.dot.ca.gov) and Airflow: production on pushes to `main`, staging on pushes to `staging/official`.

On PRs it compiles without uploading anything, posts Airflow plans, and runs advisory CI checks (an empty build of changed models into `ci_pr_<number>*` datasets and BigQuery dry-run estimates), reported in a PR comment. PRs no longer write to shared staging.

For more details, check [iac/cal-itp-data-infra/airflow/us/variables.tf](https://github.com/cal-itp/data-infra/blob/main/iac/cal-itp-data-infra/airflow/us/variables.tf).

## dbt-ci-cleanup.yml

Deletes the `ci_pr_<number>*` BigQuery datasets created by `deploy-dbt.yml`'s CI checks when a PR closes, and daily sweeps any older than three days.

## deploy-kubernetes.yml

This workflow deploys changes to the production Kubernetes cluster when they get merged into the `main` branch.

## preview-kubernetes.yml

This workflow renders kubectl diffs on PRs changing cluster content.

## rebuild-staging.yml

Manually drops staging tests: resets `staging/official` to `main`, re-merges the other running tests and force-pushes. The deploys then restore the dropped tests' files from `main`.

## publish-docs.yml

This workflow builds jupyter book docs and publishes docs to GitHub Pages.

## staging-gate.yml

Sets the required `staging/gate` status on every open PR into `main`: a PR that carries a tested change must match `staging/official`, and other PRs wait while a staging test holds a file they change. Also comments when a PR contains commits from a dropped staging test.

## staging-guards.yml

Sets the required `staging/guards` status on every open PR into `staging/official`: no `iac/` changes, no `staging/official` history in the branch, and no files held by another test (such PRs wait).

## staging-monitor.yml

Runs every 30 minutes: catches up a stale sync and manages the incident issue, handles test expiry, resets `staging/official` to `main` when nothing differs, rewrites the status issue and re-evaluates the staging checks.

## sync-staging-official.yml

On every push to `main`, merges `main` into `staging/official`. If that conflicts, the test holding the conflicting files is dropped and its author notified.

## terraform-plan.yml

When creating a PR that changes any file in the `iac` directory (Infrastructure as Code), this workflow runs `Terraform plan` to create a comment with an execution plan to preview the changes that will be made to the infrastructure. On PRs into `main`, staging plans for the modules that deploy code (`airflow/us`, `composer/us`, `gtfs-rt-archiver/us`) are computed on `staging/official` with the PR merged in.

## terraform-apply.yml

When changes to the `iac` directory are pushed, this workflow runs `Terraform apply`. Production and staging infrastructure apply from `main`; the three staging modules that deploy code (`airflow/us`, `composer/us`, `gtfs-rt-archiver/us`) apply only from `staging/official`. Running it manually on `staging/official` re-applies those three.

## test-staging-scripts.yml

Runs the tests for `.github/scripts/` on PRs that change them.
