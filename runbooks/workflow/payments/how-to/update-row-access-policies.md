# Update Row Access Policies

**Task:** Add or modify row-level security policies for payments data\
**Time Required:** 15-30 minutes\
**Prerequisites:** GitHub write access, understanding of agency identifiers

## Overview

Row access policies control which service accounts can access which agencies' data in BigQuery. This guide shows you how to add or update these policies when onboarding agencies or making changes to data access.

## Understanding Row Access Policies

**What they do:**

- Restrict BigQuery table access based on data values (e.g., participant_id, organization_name)
- Ensure agencies only see their own data
- Applied automatically when service accounts query tables

**Where they're defined:**

- File: `warehouse/macros/create_row_access_policy.sql`
- Applied to: Mart tables in `mart_payments` dataset via dbt post-hooks

**How they're applied:**

The macros are called as post-hooks in dbt model configurations. For example, see:

- [`fct_payments_rides_v2.sql`](../../../warehouse/models/mart/payments/fct_payments_rides_v2.sql) - Littlepay policy
- [`fct_payments_rides_enghouse.sql`](../../../warehouse/models/mart/payments/fct_payments_rides_enghouse.sql) - Enghouse policy
- [`fct_elavon__transactions.sql`](../../../warehouse/models/mart/payments/fct_elavon__transactions.sql) - Elavon policy

**Three separate policies:**

1. `payments_littlepay_row_access_policy` - For Littlepay agencies
2. `payments_enghouse_row_access_policy` - For Enghouse agencies
3. `payments_elavon_row_access_policy` - For Elavon data

## When to Update Policies

Update row access policies when:

- ✅ Onboarding a new agency
- Infrequent:
  - Creating a new service account for an existing agency
  - Changing an agency's identifier (participant_id, operator_id, organization_name)
  - Granting additional access to Cal-ITP team members

## Step 1: Identify the Correct Policy

Determine which policy (or policies) to update:

### For Littlepay Agencies

- **Policy:** `payments_littlepay_row_access_policy`
- **Filter field:** `participant_id`
- **Example value:** `'mst'`, `'sbmtd'`, `'ccjpa'`

### For Enghouse Agencies

- **Policy:** `payments_enghouse_row_access_policy`
- **Filter field:** `operator_id`
- **Example value:** `'253'` (note: quoted string)

### For Elavon Data

- **Policy:** `payments_elavon_row_access_policy`
- **Filter field:** `organization_name`
- **Example value:** `'Monterey-Salinas Transit'`, `'Ventura County Transportation Commission'`

## Step 2: Add Entry to Policy

### 2.1 Open the Macro File

Navigate to `warehouse/macros/create_row_access_policy.sql` and open the file.

### 2.2 Add Littlepay Policy Entry

Find the `payments_littlepay_row_access_policy` macro and add a new entry, using previous entries as a template:

**Example:**

```sql
{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = '<participant-id>',
    principals = ['serviceAccount:<agency>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};
```

**Note:** The `filter_value` should match exactly what appears in the Littlepay data.

### 2.3 Add Enghouse Policy Entry

Find the `payments_enghouse_row_access_policy` macro and add a new entry, using previous entries as a template:

**Example:**

```sql
{{ create_row_access_policy(
    filter_column = 'operator_id',
    filter_value = '<operator-id>',
    principals = ['serviceAccount:<agency>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};
```

**Note:** The `filter_value` should match exactly what appears in the Enghouse data.

### 2.4 Add Elavon Policy Entry

Find the `payments_elavon_row_access_policy` macro and add a new entry, using previous entries as a template:

**Example:**

```sql
{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = '<elavon-organization-name>',
    principals = ['serviceAccount:<agency>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};
```

**Note:** By using `organization_name` here, as opposed to Elavon `customer_name`, we make the organization's Elavon transaction history available, as opposed to just the history for a single `customer_name` for those agencies who have changed customer names over time. The `filter_value` should match exactly what appears in the Enghouse data.

## Step 3: Verify Syntax

### 3.1 Check for Common Mistakes

- [ ] Service account email is correct
- [ ] Filter value matches data exactly (case-sensitive)
- [ ] Commas, semicolons, brackets are in the right places
- [ ] Square brackets around principals array

## Step 4: Commit and Deploy

### 4.1 Merge Changes

Commit changes, create a pull request, got a review, and merge your PR.

### 4.3 Wait for dbt Rebuild

After merging, the row access policies are applied when dbt models rebuild:

- **Automatic:** Daily dbt run via DAG
- **Manual:** Trigger dbt run in Airflow if needed

## Step 5: Verify Policy Works

### 5.1 Test in Metabase

1. Log into Metabase as a test user

- For more information on creating a test user account, see section `7.2 Test as Agency User` in [Create Agency Metabase Dashboards](create-metabase-dashboards.md))

2. Navigate to the agency's database, and open a mart table
3. You should only see data rows for that agency

## Granting Cal-ITP Team Access

Cal-ITP team members who are added to the `DOT_DDS_Data_Pipeline_and_Warehouse_Users` workforce pool group have access to all payments data via the inclusion of the pool in the macros here:

```sql
{{ create_row_access_policy(
    principals = [
        'serviceAccount:metabase@cal-itp-data-infra.iam.gserviceaccount.com',
        'serviceAccount:metabase-payments-team@cal-itp-data-infra.iam.gserviceaccount.com',
        'serviceAccount:github-actions-service-account@cal-itp-data-infra.iam.gserviceaccount.com',
        'serviceAccount:composer-service-account@cal-itp-data-infra.iam.gserviceaccount.com',
        'principalSet://iam.googleapis.com/locations/global/workforcePools/dot-ca-gov/group/DDS_Cloud_Admins',
        'principalSet://iam.googleapis.com/locations/global/workforcePools/dot-ca-gov/group/DOT_DDS_Data_Pipeline_and_Warehouse_Users'
    ]
) }};
```

**Note:** Cal-ITP team members should be added to the `DOT_DDS_Data_Pipeline_and_Warehouse_Users` GCP workforce pool group to access all payments data.

## Troubleshooting

### Policy Not Working

**Symptoms:** Service account can see other agencies' data or no data

**Solutions:**

- Verify dbt models have been rebuilt since policy change
- Check filter value matches data exactly (case-sensitive)
- Confirm service account email is correct
- Test query directly in BigQuery
- Check for SQL syntax errors in macro

### Permission Denied Errors

**Symptoms:** "Permission denied" when querying tables

**Solutions:**

- Verify service account has BigQuery user role
- Check service account is listed in row access policy
- Confirm correct policy was applied (check dbt logs)
- Ensure the user is added to the user group pool (for internal users - if relevant)

### Filter Value Mismatch

**Symptoms:** Policy exists but returns no data

**Solutions:**

Query the table to see actual values:

```sql
SELECT DISTINCT participant_id 
FROM `cal-itp-data-infra.mart_payments.fct_payments_rides_v2`;
```

- Update policy with exact value
- Check for leading/trailing spaces
- Verify case sensitivity

## Best Practices

1. **Review carefully** - There are security implications here!
2. **Always test policies** before considering them complete
3. **Use exact values** from the data (query first, then add policy)
4. **Document changes** in commit messages

## Related Documentation

- [Onboard a New Littlepay Agency](onboard-littlepay-agency.md)
- [Onboard a New Enghouse Agency](onboard-enghouse-agency.md)
- [Onboard a New Elavon Agency](onboard-elavon-agency.md)
- [Create Agency Metabase Dashboards](create-metabase-dashboards.md)

______________________________________________________________________

**See Also:** For conceptual understanding of row-level security, see the [BigQuery Row-Level Security documentation](https://cloud.google.com/bigquery/docs/row-level-security-intro)
