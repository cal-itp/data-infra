# Description

_Describe your changes and why you're making them. Please include the context, motivation, and relevant dependencies._

Resolves #\[issue\]

## Type of change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation

## How has this been tested?

_Include commands/logs/screenshots as relevant._

_If making changes to dbt models, make sure they were created or update on Staging. Please run the command `poetry run dbt run -s CHANGED_MODEL --target staging` and `poetry run dbt test -s CHANGED_MODEL --target staging`, then include the output in this section of the PR._

## Post-merge follow-ups

_Document any actions that must be taken post-merge to deploy or otherwise implement the changes in this PR (for example, running a full refresh of some incremental model in dbt). If these actions will take more than a few hours after the merge or if they will be completed by someone other than the PR author, please create a dedicated follow-up issue and link it here to track resolution._

- [ ] No action required
- [ ] Actions required (specified below)
