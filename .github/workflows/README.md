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

## GitOps

The workflows described above also define their triggers. In general, developer workflows should follow these steps.

1. Check out a feature branch
2. Put up a PR for that feature branch, targeting `main`
   - `service-release-candidate` will run and create a remote branch named `candidate/<feature-branch-name`
3. Create and merge a PR from the candidate branch to `releases/test`
   - `service-release-diff` will run on the PR and print the expected changes
   - `service-release-channel` will run on merge (i.e. push on `releases/test`) and deploy
4. Merge the original PR
   - `service-release-candidate` will then update the remote `candidates/main` branch
5. Create and merge a PR from `candidates/main` to `releases/prod`
   - `service-release-channel` will run and deploy to `prod` this time

Note: One alternative would be to use `candidates/main` to deploy into both `test` and `prod`. This is very possible but can be a bit annoying if GitHub is configured to delete branches on merge and the `cleanup-release-candidates` action then deletes `candidates/main` after it has been merged into `releases/test`.
