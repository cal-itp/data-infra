# Sentry triage
> Important Sentry concepts:
> * [Fingerprintinga and grouping](https://docs.sentry.io/product/sentry-basics/grouping-and-fingerprints/)
> * [Merging issues](https://docs.sentry.io/product/data-management-settings/event-grouping/merging-issues/)

Once a day, we should check Sentry issues created since the prior day

Categorize those issues and perform relevant steps if the issue is not already assigned.

### A fingerprinting error (i.e. new issue that should’ve been grouped)
1. Merge the issue into any existing issues
2. Create a GitHub issue to update the fingerprint
### Bug, or external issue handleable by retry
1. Create a GitHub issue to fix the bug (or add a retry) and assign if there is a clear owner
2. Resolve on deploy
### External, and a retry does not handle it
> e.g. SBMTD 500s in RT

No-op for now
