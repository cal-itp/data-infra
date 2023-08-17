# CI - deploys via pyinvoke

This folder contains code and YAML that drives the deployments of Kubernetes-based applications and services. For example,
a deployment named `archiver` is configured in [the prod channel](./channels/prod.yaml) and is ultimatedly deployed
by `invoke` (see below) calling `kubectl` commands.

## invoke (aka pyinvoke)
[invoke](https://docs.pyinvoke.org/en/stable/) is a Python framework for executing subprocesses and building a CLI application.
The tasks are defined in `tasks.py` and configuration in `invoke.yaml`; config values under the top-level `calitp`
are specific to our defined tasks.

Run `poetry run invoke -l` to list the available commands, and `poetry run invoke -h <command>` to get more detailed help for each individual command.
Individual release channels/environments are config files that are passed to invoke. For example, to deploy to test:

```bash
poetry run invoke release -f channels/test.yaml
```

## GitOps

```mermaid
flowchart TD
classDef default fill:white, color:black, stroke:black, stroke-width:1px
classDef group_labelstyle fill:#cde6ef, color:black, stroke-width:0px
class ingestion_label,modeling_label,analysis_label group_labelstyle

pr[Push commits to a branch.\nTest environment?]
candidates_branch[GitHub Action renders candidates/branch-name]
branch_diff[invoke diff renders on test PR]
branch_invoke[invoke releases to test]

candidates_main[GitHub Action builds images and renders candidates/main]
prod_diff[invoke diff renders on prod PR]
prod_invoke[invoke releases to prod]

pr -- Yes --> candidates_branch -- "Open PR from candidates/branch-name to releases/test" --> branch_diff -- "Merge candidate PR to releases/test" --> branch_invoke -- Merge to main after review and testing. --> candidates_main -- "Open PR from candidates/main to releases/prod" --> prod_diff -- "Merge candidate PR to releases/prod" --> prod_invoke
pr -- "No; merge to main after review" --> candidates_main
```
