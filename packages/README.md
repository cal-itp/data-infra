# Cal-ITP Python Packages

We publish [calitp-data-analysis](https://pypi.org/project/calitp-data-analysis/) and [calitp-data-infra](https://pypi.org/project/calitp-data-infra/), two Python packages that enable work elsewhere in the repository. Each is maintained and deployed the same way.

## Testing Changes

Each package should pass mypy and other static checkers, and each has a small
number of tests. These checks are executed in GitHub Actions when a PR is opened:

- [calitp-data-analysis](../.github/workflows/build-calitp-data-analysis.yml)
- [calitp-data-infra](../.github/workflows/build-calitp-data-infra.yml)

## Deploying Changes to Production

When changes are finalized, a new version number should be specified in the relevant package's [pyproject.toml](./pyproject.toml) file. When changes to the package directory are merged into `main`, the relevant GitHub Action (`build-calitp-data-analysis` or `build-calitp-data-infra`) automatically publishes an updated version of the package to PyPI. A contributor with proper PyPI permissions can also manually release a new version of the targeted package via the CLI, or test a release using [TestPyPI](https://packaging.python.org/en/latest/guides/using-testpypi/). To obtain those permissions, the owner of the PyPI project must grant your PyPI account Maintainer status through the project's Manage pane on [the PyPI website](https://pypi.org/).

After deploying, it is likely that changes will need to be made to `requirements.txt` files, Dockerfiles, and other place across the ecosystem where the previous package version number is referenced. Each of these places will have their own deployment needs.
