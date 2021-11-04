# Submitting Changes (WIP)

## Commits and Pull Requests (PR)

* Follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) standard for all commits
* Use Conventional Commit format for PR titles
* Use GitHub's *draft* status to indicate PRs that are not ready for review/merging
* Do not use GitHub's "update branch" button or merge the `main` branch back into a PR branch to update it. Instead, rebase PR branches to update them and resolve any merge conflicts.

## How do I preview my documentation change?
You can preview it in the github pages or run the jupyterbook locally using the following command:
```
jb build docs
```
if no code has been altered, to force jupyterbook to rebuild use the following command:

```
jb build docs --all
```
## How is the documentation gh action triggered?
The action is triggered on push, meaning the github action is triggered when code is pushed the the main branch in respository
