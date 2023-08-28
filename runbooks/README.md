# Runbooks

This folder contains two types of runbooks:

- **Data** runbooks are Jupyter notebooks that record steps taken to run specific data migrations or manipulations (for example, changing partitions by migrating data from one bucket to another or changing object metadata in place.) They can be used as reference materials when new migrations are needed, but they may not be runnable in their current form (i.e., they are not expected to be kept up to date; they are meant to capture how a specific migration happened when it was run.)
- **Workflow** runbooks document general/repeatable processes (for example, Sentry new issue triage) in a non-runnable Markdown document. These should be kept up to date and reflect the current state of the relevant workflow.
