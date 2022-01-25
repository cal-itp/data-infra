(submitting-changes)=
# Submitting Changes

## Updating Options

### Update on GitHub (Website)
These documents are currently editable on the web with GitHub. To use the GitHub website to make changes:
* Click the GitHub icon in the top right of the page and choose `Suggest Edit` to navigate to GitHub.
* Make changes on that page using [Markdown](content-types) formatting.
* At the bottom of the page, where it says `Commit changes`, add a title for your updates and a description. Make sure to being the title with `(Docs)`.
* Select the second option `Create a new branch...` and add a short but descriptive name for this new branch.
* Select `Commit Changes` which with create a Pull Request (PR) to submit your addition for review and merge.

### Update with Git (Command Line)

* Follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) standard for all commits
* Use Conventional Commit format for PR titles
    * Install pre-commit hooks
    * `pip install pre-commit`, `pre-commit install`
    * If needed, run `pre-commit run --all-files` to run the hooks on all files, not just those staged for changes.
* Use GitHub's *draft* status to indicate PRs that are not ready for review/merging
* Do not use GitHub's "update branch" button or merge the `main` branch back into a PR branch to update it. Instead, rebase PR branches to update them and resolve any merge conflicts.

## How do I preview my documentation change?
You can preview it in the GitHub pages or run the Jupyter-Book locally using the following command:
```
jb build docs
```
if no code has been altered, to force Jupyter-Book to rebuild use the following command:

```
jb build docs --all
```
## How is the documentation GitHub action triggered?
The action is triggered on push, meaning the GitHub action is triggered when code is pushed the the main branch in repository
