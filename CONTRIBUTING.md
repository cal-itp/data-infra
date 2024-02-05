# Contribution guidelines

These guidelines are meant to provide a foundation for collaboration in Cal-ITP's data services repos,
primarily [data-infra](https://github.com/cal-itp/data-infra).

## Issues

- When submitting an issue, please try to use an existing template if one is appropriate
- Provide enough information and context; try to do one or more of the following:
  - Include links to specific lines of code, error logs, Slack context, etc.
  - Include error messages or tracebacks if relevant and short
  - Connect issues to Sentry issues

## Pull Requests

- We generally use merge commits as we think they provide clarity in a PR-based workflow
- PRs should be linked to any issues that they close. [Keywords](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword) are one good way to do this
- Google provides a [How to do a code review reference](https://google.github.io/eng-practices/review/reviewer/) that reviewers may find helpful
- Use draft PRs to keep track of work without notifying reviewers, and avoid giving pre-emptive feedback on draft PRs
- Reviewers should not generally merge PRs themselves and should instead let the author merge, since authors will have the most context about merge considerations (for example, whether additional reviews are still needed, or whether any communication is needed about the impacts of the PR when it merges)
- After a PR is merged, the author has the responsibility of monitoring any subsequent CI actions for successful completions
