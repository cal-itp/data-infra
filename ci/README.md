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

In this diagram, arrows represent human actions such as opening and merging PRs and nodes (except for the very first) represent automated actions such as `invoke` deploying to the cluster. Green nodes indicate a deployment while white nodes indicate an automated git action such as branch creation or commenting on a pull request.

```mermaid
flowchart TD
classDef default fill:white, color:black, stroke:black
classDef initial fill:lightblue, color:black
classDef deploy fill:lightgreen, color:black

pr[Push commits to a branch.\nDoes a test environment exist?]
candidates_branch[GitHub Action renders candidates/branch-name]
branch_diff[invoke diff renders on test PR]
branch_invoke[invoke releases to test]

candidates_main[GitHub Action builds images and renders candidates/main\nNote: if you stop here, no Kubernetes changes will actually be deployed.]
prod_diff[invoke diff renders on prod PR]
prod_invoke[invoke releases to prod]

pr -- Yes --> candidates_branch -- "Open PR from candidates/branch-name to releases/test" --> branch_diff -- "Merge candidate PR to releases/test" --> branch_invoke -- Merge original PR to main after review and testing --> candidates_main -- "Open PR from candidates/main to releases/prod" --> prod_diff -- "Merge candidate PR to releases/prod" --> prod_invoke
pr -- "No; merge to main after review" --> candidates_main

class pr initial
class branch_invoke,prod_invoke deploy
```
