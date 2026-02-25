# Rotate Littlepay AWS Keys

**Task:** Rotate AWS IAM keys for Littlepay data access\
**Time Required:** 30-45 minutes per agency\
**Prerequisites:** AWS CLI access, GCP Secret Manager permissions\
**Frequency:** Every 90 days (Littlepay requirement)

## Overview

Littlepay requires that AWS IAM keys used to access their S3 data feeds be rotated every 90 days for security. This guide walks you through the rotation process for a single agency.

> **Note:** This is adapted from the original documentation with enhancements. Based on [AWS key rotation best practices](https://aws.amazon.com/blogs/security/how-to-rotate-access-keys-for-iam-users/).

## Before You Start

### Prerequisites

- [ ] AWS CLI installed and configured
- [ ] Access to GCP Secret Manager
- [ ] AWS profile configured for the agency
- [ ] Ability to test Airflow DAGs

### Information Needed

- [ ] Agency merchant ID (e.g., `mst`, `sbmtd`)
- [ ] AWS username (may differ from merchant_id)
- [ ] Secret name in Secret Manager
- [ ] AWS profile name

## Key Rotation Process Overview

```mermaid
graph LR
    A[Create New Key] --> B[Store in Secret Manager]
    B --> C[Disable Old Key]
    C --> D[Test Sync DAG]
    D --> E{Tests Pass?}
    E -->|Yes| F[Delete Old Key]
    E -->|No| G[Re-enable Old Key]
    G --> H[Troubleshoot]
    H --> D
```

## Step 1: Create New AWS Access Key

### 1.1 List Existing Keys

First, identify the current key:

```bash
# List access keys for the user
aws iam list-access-keys \
  --user-name <username> \
  --profile <merchant-id>
```

**Example output:**

```json
{
    "AccessKeyMetadata": [
        {
            "UserName": "mst-default",
            "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
            "Status": "Active",
            "CreateDate": "2023-10-15T10:30:00Z"
        }
    ]
}
```

**Note the:**

- Current `AccessKeyId`
- `CreateDate` (to verify it's >90 days old)

### 1.2 Create New Access Key

```bash
# Create new access key
aws iam create-access-key \
  --user-name <username> \
  --profile <merchant-id>
```

**Example output:**

```json
{
    "AccessKey": {
        "UserName": "mst-default",
        "AccessKeyId": "AKIAI44QH8DHBEXAMPLE",
        "Status": "Active",
        "SecretAccessKey": "je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY",
        "CreateDate": "2024-01-15T10:30:00Z"
    }
}
```

**Important:** Save this output! The `SecretAccessKey` is only shown once.

### 1.3 Format as JSON

**Recommended Approach:** Work directly in Secret Manager to avoid saving credentials locally:

1. Navigate to [Secret Manager](https://console.cloud.google.com/security/secret-manager?project=cal-itp-data-infra)
2. Find an existing Littlepay secret (e.g., `LITTLEPAY_AWS_IAM_MST_ACCESS_KEY`)
3. Click to view the current version
4. Copy the JSON content
5. Paste into a text editor
6. Replace the old `AccessKeyId` and `SecretAccessKey` with the new values from Step 1.2
7. Keep the `UserName` the same (unless it changed)

**Example format:**

```json
{
  "AccessKeyId": "AKIAI44QH8DHBEXAMPLE",
  "SecretAccessKey": "je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY",
  "UserName": "mst-default"
}
```

**Alternative (if working locally):** Save as `<merchant-id>-new-key.json`, but delete immediately after uploading to Secret Manager.

## Step 2: Store New Key in Secret Manager

Google Secret Manager supports versioning, allowing you to store multiple versions of the same secret.

### 2.1 Add New Secret Version

**Via GCP Console:**

1. Navigate to [Secret Manager](https://console.cloud.google.com/security/secret-manager?project=cal-itp-data-infra)
2. Find `LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY`
3. Click on the secret name
4. Click **New Version**
5. Paste the JSON content
6. Click **Add new version**

**Via gcloud CLI:**

```bash
# Add new version
cat <merchant-id>-new-key.json | gcloud secrets versions add \
  LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY \
  --project=cal-itp-data-infra \
  --data-file=-
```

### 2.2 Verify New Version

```bash
# List versions
gcloud secrets versions list \
  LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY \
  --project=cal-itp-data-infra
```

You should see two versions:

- Older version (currently in use)
- Newer version (just created)

**Note:** The newest version is automatically used by default.

## Step 3: Test New Key

### 3.1 Test Locally

Update your local AWS profile with the new key:

```bash
# Configure with new credentials
aws configure --profile <merchant-id>
# Enter new AccessKeyId
# Enter new SecretAccessKey
# Region: us-west-2
# Output format: json

# Test access
aws s3 ls s3://littlepay-<merchant-id>/ --profile <merchant-id>
```

**Expected:** List of directories (device_transactions, micropayments, etc.)

### 3.2 Test Sync DAG

The sync DAG will automatically use the latest version of the secret.

**Option A: Trigger Manual Run**

1. Navigate to [Airflow UI](https://b2062ffca77d44a28b4e05f8f5bf4996-dot-us-west2.composer.googleusercontent.com/dags/sync_littlepay/grid)
2. Find `sync_littlepay_v3` DAG
3. Click **Trigger DAG**
4. Monitor the run for your agency's tasks
5. Check logs for successful S3 access

**Option B: Wait for Scheduled Run**

1. Wait for next hourly run
2. Monitor the DAG run
3. Verify success for your agency

### 3.3 Verify Data Sync

Check that new data was synced:

```bash
# List recent raw files
gsutil ls -l gs://calitp-littlepay-raw/<merchant-id>/device_transactions/ | tail -5
```

Verify timestamps are recent (within the last hour).

## Step 4: Disable Old Key

**Important:** Only disable after confirming the new key works!

### 4.1 Disable Old Key in AWS

```bash
# Disable the old key (don't delete yet!)
aws iam update-access-key \
  --access-key-id <old-access-key-id> \
  --status Inactive \
  --user-name <username> \
  --profile <merchant-id>
```

### 4.2 Verify Key Status

```bash
# List keys to confirm status
aws iam list-access-keys \
  --user-name <username> \
  --profile <merchant-id>
```

You should see:

- Old key: `Status: "Inactive"`
- New key: `Status: "Active"`

## Step 5: Monitor and Verify

### 5.1 Monitor Next Sync Run

Wait for the next scheduled sync run (hourly) and verify:

- [ ] Sync DAG completes successfully
- [ ] No AWS authentication errors in logs
- [ ] New data appears in GCS
- [ ] Parse DAG runs successfully

### 5.2 Check for Errors

```bash
# Check Airflow logs for errors
# Look for "Access Denied" or authentication failures
```

If you see errors, proceed to Step 6 (Rollback).

## Step 6: Delete Old Key (After Verification)

**Wait at least 24 hours** after disabling the old key to ensure everything works.

### 6.1 Delete Old Key from AWS

```bash
# Delete the old key permanently
aws iam delete-access-key \
  --access-key-id <old-access-key-id> \
  --user-name <username> \
  --profile <merchant-id>
```

### 6.2 Disable Old Secret Version (Optional)

In Secret Manager, you can disable (but not delete) the old version:

**Via GCP Console:**

1. Navigate to the secret
2. Find the old version
3. Click **...** menu → **Disable**

**Via gcloud CLI:**

```bash
# Disable old version
gcloud secrets versions disable <version-number> \
  --secret=LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY \
  --project=cal-itp-data-infra
```

**Note:** Keep old versions disabled rather than deleting them for audit purposes.

## Rollback Procedure

If the new key doesn't work, rollback immediately:

### Rollback Step 1: Re-enable Old Key in AWS

```bash
# Re-enable the old key
aws iam update-access-key \
  --access-key-id <old-access-key-id> \
  --status Active \
  --user-name <username> \
  --profile <merchant-id>
```

### Rollback Step 2: Revert to Old Secret Version

**Via GCP Console:**

1. Navigate to Secret Manager
2. Find the secret
3. Click on the old version
4. Note the version number
5. You cannot set it as "latest" directly, but you can add it as a new version

**Via gcloud CLI:**

```bash
# Get the old version's value
gcloud secrets versions access <old-version-number> \
  --secret=LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY \
  --project=cal-itp-data-infra > old-key.json

# Add it as a new version (becomes latest)
cat old-key.json | gcloud secrets versions add \
  LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY \
  --project=cal-itp-data-infra \
  --data-file=-
```

### Rollback Step 3: Verify

Test the sync DAG again to confirm the rollback worked.

### Rollback Step 4: Troubleshoot

Investigate why the new key failed:

- Check AWS IAM permissions
- Verify S3 bucket access
- Check for typos in the key
- Confirm username is correct

## Rotating Multiple Agencies

If rotating keys for multiple agencies:

### Best Practices

1. **Rotate one at a time** - Don't rotate all agencies simultaneously
2. **Stagger rotations** - Space them out over days/weeks
3. **Document each rotation** - Keep a log of what was rotated when
4. **Test thoroughly** - Don't rush through verification

### Tracking Rotations

**Recommendation:** Create a central tracking spreadsheet (e.g., in SharePoint or Google Sheets) to track key rotations across all agencies.

**Suggested columns:**

| Agency | Merchant ID | Last Rotation | Next Due   | Status         | Rotated By |
| ------ | ----------- | ------------- | ---------- | -------------- | ---------- |
| MST    | mst         | 2024-01-15    | 2024-04-15 | ✅ Complete    | Jane Doe   |
| SBMTD  | sbmtd       | 2024-01-20    | 2024-04-20 | 🔄 In Progress | John Smith |

**Benefits of central tracking:**

- Team visibility into rotation status
- Prevents duplicate work
- Easy to identify overdue rotations
- Historical record for auditing

### Automation Considerations

Consider creating a script to:

- List all Littlepay secrets
- Check creation dates
- Alert when keys are approaching 90 days
- Automate the rotation process

## Troubleshooting

### "Access Denied" After Rotation

**Symptoms:** Sync DAG fails with AWS access denied

**Solutions:**

- Verify new key is active in AWS
- Check Secret Manager has the correct new key
- Confirm Airflow is using latest secret version
- Test key locally with AWS CLI
- Rollback if necessary

### Old Key Still Being Used

**Symptoms:** Disabling old key breaks sync

**Solutions:**

- Secret Manager may be cached
- Wait a few minutes for cache to clear
- Trigger DAG manually to force refresh
- Check secret version is set to "latest"

### Cannot Create New Key

**Symptoms:** AWS returns error when creating key

**Solutions:**

- Check if user already has 2 keys (AWS limit)
- Delete or disable one key first
- Verify IAM permissions
- Check username is correct

### Secret Manager Version Issues

**Symptoms:** Wrong version being used

**Solutions:**

- Verify latest version is enabled
- Check no version is explicitly pinned in code
- Disable old versions to force use of new
- Clear any caches

## Related Documentation

- [Onboard a New Littlepay Agency](onboard-littlepay-agency.md)
- [Troubleshoot Data Sync Issues](troubleshoot-sync-issues.md)

## Key Rotation Checklist

Use this checklist for each rotation:

- [ ] Identify agency and current key
- [ ] Create new AWS access key
- [ ] Format as JSON
- [ ] Add new version to Secret Manager
- [ ] Test new key locally
- [ ] Trigger sync DAG test run
- [ ] Verify data syncs successfully
- [ ] Disable old key in AWS
- [ ] Monitor next scheduled sync
- [ ] Wait 24 hours
- [ ] Delete old key from AWS
- [ ] Disable old secret version
- [ ] Update rotation tracking spreadsheet
- [ ] Document any issues encountered

______________________________________________________________________

**See Also:** [AWS Key Rotation Best Practices](https://aws.amazon.com/blogs/security/how-to-rotate-access-keys-for-iam-users/)
