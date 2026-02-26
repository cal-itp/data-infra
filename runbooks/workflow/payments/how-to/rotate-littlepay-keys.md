# Rotate Littlepay AWS Keys

**Task:** Rotate AWS IAM keys for Littlepay data access\
**Time Required:** 30-45 minutes\
**Prerequisites:** AWS CLI access, GCP Secret Manager permissions\
**Frequency:** Every 90 days (Littlepay requirement)

## Overview

Littlepay requests that clients accessing their raw data feeds through S3 rotate the IAM keys every 90 days. AWS provides [general instructions for doing so with the `aws` CLI tool](https://aws.amazon.com/blogs/security/how-to-rotate-access-keys-for-iam-users/). The following gives additional context on the Cal-ITP setup, and should be used in conjunction with those instructions.

## Create and Store New Credentials

First, follow the instructions linked above to create a new set of AWS keys for the client. The command you use to do so will look something like this:

```bash
aws iam create-access-key --user-name <username> --profile <profile>
```

Google Secret Manager allows you to store multiple versions of the same secret as you update the secret's value over time. Once you've created an updated key in AWS using the instructions above, [create a new version of the corresponding secret in Secret Manager](https://cloud.google.com/secret-manager/docs/add-secret-version) and paste the new AWS key as the value stored inside the new version of the secret (following the same format as the existing keys).

If you prefer, you can use the Google Cloud CLI to create new versions of secrets, but [the web UI](https://console.cloud.google.com/security/secret-manager?project=cal-itp-data-infra) contains the same functionality:

```bash
gcloud secrets versions add ...
```

## Disable Old Credentials and Test New Credentials

[Disable (*do not destroy*) the old versions in Secret Manager](https://cloud.google.com/secret-manager/docs/disable-secret-version) and test the `sync_littlepay` Airflow DAG, which is the primary integration with Littlepay in the v2 pipeline.

## Delete Old Credentials from AWS

Assuming all tests succeed, delete the old credentials from AWS:

```bash
aws iam delete-access-key --access-key-id <old-access-key-id> --profile <profile>
```

## Related Documentation

- [Onboard a New Littlepay Agency](onboard-littlepay-agency.md)
- [Troubleshoot Data Sync Issues](troubleshoot-sync-issues.md)
