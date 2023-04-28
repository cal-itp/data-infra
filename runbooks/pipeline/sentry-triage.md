# Sentry triage
> Important Sentry concepts:
> * [Issue states](https://docs.sentry.io/product/issues/states-triage/)
> * [Fingerprintinga and grouping](https://docs.sentry.io/product/sentry-basics/grouping-and-fingerprints/)
> * [Merging issues](https://docs.sentry.io/product/data-management-settings/event-grouping/merging-issues/)

Once a day, we should check Sentry issues created since the prior day, using the following query.

`is:unresolved firstSeen:-24h ` ([saved search link](https://sentry.calitp.org/organizations/sentry/issues/searches/3/?environment=cal-itp-data-infra&project=2&referrer=issue-list&sort=date&statsPeriod=24h))

Categorize those issues and perform relevant steps if the issue is not already assigned.

### A fingerprinting error (i.e. new issue that should’ve been grouped)
1. Merge the issues together.
![](sentry_merging.png)
2. Create a GitHub issue to update the fingerprint, linking to the now-merged issue.

### Bug, or external issue handleable by retry
1. Create a GitHub issue to fix the bug (or add a retry) and assign if there is a clear owner.

![](create_github_issue_from_sentry.png)

2. In the eventual PR that should fix the issue, resolving the GitHub issue should also resolve the Sentry issue. You can also reference a Sentry issue to close directly via the PR description, e.g. `fixes CAL-ITP-DATA-INFRA-D5`.

### External, and a retry does not handle it
> e.g. SBMTD 500s in RT
No-op for now
