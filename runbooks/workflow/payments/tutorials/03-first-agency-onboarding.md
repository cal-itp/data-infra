# Your First Agency Onboarding

**Tutorial Duration:** ~30 minutes (reading) + 2 hours (hands-on)\
**Prerequisites:** [Understanding the Data Flow](02-understanding-data-flow.md), GCP access with appropriate permissions\
**What You'll Learn:** The complete agency onboarding process through a guided walkthrough

## Introduction

This tutorial guides you through onboarding a new agency to the payments ecosystem. Rather than repeating detailed instructions (which are in the how-to guides), this tutorial focuses on:

- **Understanding the overall process** and how steps connect
- **Learning checkpoints** to verify your progress
- **Common decision points** and why they matter
- **The "why" behind each step**

**For detailed step-by-step instructions**, refer to:

- [Onboard a New Littlepay Agency](../how-to/onboard-littlepay-agency.md)
- [Onboard a New Enghouse Agency](../how-to/onboard-enghouse-agency.md)
- [Onboard a New Elavon Agency](../how-to/onboard-elavon-agency.md)
- [Create Agency Metabase Dashboards](../how-to/create-metabase-dashboards.md)

## Learning Scenario

You're onboarding **Demo Transit**, a small agency using:

- **Littlepay** for fare collection (participant_id: `demo-transit`)
- **Elavon** for payment processing (organization: `Demo Transit Authority`)

## The Onboarding Journey

### Phase 1: Gather Information (15 minutes)

**What you're doing:** Collecting all necessary information before starting technical work.

**Key learning:** Onboarding requires coordination with multiple parties (vendor, agency, internal team). Missing information causes delays.

**Follow:** [Onboard Littlepay Agency - Before You Start](../how-to/onboard-littlepay-agency.md#before-you-start)

**Learning checkpoint:**

- [ ] Do you have AWS credentials from Littlepay?
- [ ] Do you know the participant_id/merchant_id?
- [ ] Do you have the agency's GTFS dataset identifier?
- [ ] Do you have Elavon organization name?

**Reflection:** Why do we need the GTFS dataset identifier? (Answer: To link payments data with routes/stops for geographic analysis)

______________________________________________________________________

### Phase 2: Store Credentials Securely (10 minutes)

**What you're doing:** Storing vendor credentials in GCP Secret Manager.

**Key learning:** We use Secret Manager (not environment variables or config files) because:

- Credentials are encrypted at rest
- Access is audited
- Rotation is easier
- Airflow can access them securely

**Follow:** [Onboard Littlepay Agency - Step 1](../how-to/onboard-littlepay-agency.md#step-1-store-aws-credentials)

**Learning checkpoint:**

- [ ] Secret created with correct naming convention
- [ ] Can retrieve secret value
- [ ] Tested AWS access locally

**Reflection:** What happens if the secret name doesn't match the sync config? (Answer: Sync DAG will fail with authentication error)

______________________________________________________________________

### Phase 3: Create Service Account (20 minutes)

**What you're doing:** Creating a dedicated service account for the agency via Terraform.

**Key learning:** We use Terraform (not manual GCP Console) because:

- Changes are version controlled
- Infrastructure is reproducible
- Changes are reviewed via PR
- Prevents configuration drift

**Follow:** [Onboard Littlepay Agency - Step 2](../how-to/onboard-littlepay-agency.md#step-2-create-service-account)

**Learning checkpoint:**

- [ ] Service account created via Terraform
- [ ] BigQuery user role granted
- [ ] Service account key downloaded
- [ ] Key stored securely for later Metabase setup

**Reflection:** Why does each agency need their own service account? (Answer: Row-level security - ensures agencies only see their own data)

______________________________________________________________________

### Phase 4: Configure Data Pipeline (30 minutes)

**What you're doing:** Setting up sync, parse, and entity mapping configurations.

**Key learning:** The pipeline has three configuration points:

1. **Sync config** - How to get data from vendor
2. **Parse config** - How to convert data format
3. **Entity mapping** - How to link payments to GTFS/organization

**Follow:** [Onboard Littlepay Agency - Step 3](../how-to/onboard-littlepay-agency.md#step-3-configure-data-sync)

**Learning checkpoint:**

- [ ] Sync YAML created with correct secret name
- [ ] Parse YAML created with matching tables
- [ ] Entity mapping row added with correct source_record_ids
- [ ] All changes committed and PR created

**Reflection:** Why do we need entity mapping? (Answer: Links Littlepay participant_id to GTFS datasets and Elavon organization name for cross-vendor reconciliation)

______________________________________________________________________

### Phase 5: Configure Row-Level Security (20 minutes)

**What you're doing:** Adding row access policies so the agency can only see their own data.

**Key learning:** Row-level security is applied at the BigQuery table level via dbt post-hooks. The policies filter based on:

- `participant_id` for Littlepay
- `operator_id` for Enghouse
- `organization_name` for Elavon

**Follow:** [Onboard Littlepay Agency - Step 4](../how-to/onboard-littlepay-agency.md#step-4-configure-row-level-security)

**Learning checkpoint:**

- [ ] Added to Littlepay policy macro
- [ ] Added to Elavon policy macro (if applicable)
- [ ] Service account email matches exactly
- [ ] Filter values match data exactly (case-sensitive!)

**Reflection:** What happens if you misspell the participant_id in the policy? (Answer: Agency won't see any data - the filter won't match)

______________________________________________________________________

### Phase 6: Verify Data Flow (45 minutes)

**What you're doing:** Confirming data flows through each stage of the pipeline.

**Key learning:** Data flows through multiple stages:

1. Raw (GCS) → 2. Parsed (GCS) → 3. External tables (BigQuery) → 4. Staging (dbt) → 5. Mart (dbt)

Each stage must complete before the next can succeed.

**Follow:** [Onboard Littlepay Agency - Step 5](../how-to/onboard-littlepay-agency.md#step-5-verify-data-pipeline)

**Learning checkpoint:**

- [ ] Raw files appear in GCS after sync DAG
- [ ] Parsed files appear in GCS after parse DAG
- [ ] External tables return data
- [ ] Staging tables have data after dbt runs
- [ ] Mart tables have data after dbt runs
- [ ] Row-level security works (tested with service account)

**Reflection:** Why do we have both external tables AND dbt staging models? (Answer: External tables make raw data queryable; staging models add light transformations and standardization)

______________________________________________________________________

### Phase 7: Set Up Metabase Dashboard (30 minutes)

**What you're doing:** Creating a dashboard for the agency to view their data.

**Key learning:** Metabase setup involves:

1. Database connection (using service account)
2. Group (for user management)
3. Collection (for organizing dashboards)
4. Permissions (who can see what)
5. Dashboard (duplicated and reconfigured)

**Follow:** [Create Agency Metabase Dashboards](../how-to/create-metabase-dashboards.md)

**Learning checkpoint:**

- [ ] Database connection created with service account
- [ ] Group created for agency users
- [ ] Collection created for agency dashboards
- [ ] Permissions set correctly
- [ ] Dashboard duplicated and reconfigured
- [ ] Agency users can access dashboard

**Reflection:** Why do we duplicate dashboards instead of sharing one? (Answer: Each agency needs their own database connection with row-level security; shared dashboards would require complex filtering)

______________________________________________________________________

## What You've Learned

By completing this tutorial, you now understand:

- ✅ **The complete onboarding workflow** from credentials to dashboard
- ✅ **Why each step matters** and how they connect
- ✅ **Common decision points** (naming conventions, configuration formats)
- ✅ **How to verify** each stage works before proceeding
- ✅ **The role of different tools** (Terraform, Airflow, dbt, Metabase)

## Key Takeaways

**1. Onboarding is a multi-stage process**

- Each stage depends on the previous one
- Verify each stage before proceeding
- Don't skip verification steps!

**2. Configuration consistency is critical**

- Secret names must match sync configs
- Participant IDs must match across all configs
- Service account emails must match exactly in policies

**3. Security is built-in, not added later**

- Service accounts created via Terraform
- Credentials stored in Secret Manager
- Row-level security applied via dbt
- Metabase uses service accounts, not user credentials

**4. Documentation is your friend**

- How-to guides have the detailed steps
- Tutorials explain the "why"
- Reference docs explain the "what"

## Common Pitfalls to Avoid

**❌ Wrong secret name format**

- Use: `LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY`
- Not: `littlepay-aws-demo-transit`

**❌ Forgetting entity mapping**

- Without it, payments won't link to GTFS routes/stops

**❌ Not waiting for dbt to run**

- Mart tables won't have data until dbt runs (daily schedule)

**❌ Typos in row access policies**

- Filter values are case-sensitive and must match data exactly

**❌ Not testing row-level security**

- Always verify with the service account before considering it done

## Next Steps

Now that you understand the onboarding process:

1. **Practice with a real agency:** Use the how-to guides for production onboarding
2. **Learn troubleshooting:** Read [Troubleshoot Data Sync Issues](../how-to/troubleshoot-sync-issues.md)
3. **Understand maintenance:** Review [Rotate Littlepay AWS Keys](../how-to/rotate-littlepay-keys.md)

## Quick Reference: Onboarding Checklist

Use this for real onboarding:

- [ ] Gather all prerequisites
- [ ] Store credentials in Secret Manager
- [ ] Create service account via Terraform
- [ ] Download service account key
- [ ] Create sync configuration
- [ ] Create parse configuration
- [ ] Add entity mapping
- [ ] Add row access policies
- [ ] Verify sync DAG runs
- [ ] Verify parse DAG runs
- [ ] Verify external tables have data
- [ ] Verify dbt models run
- [ ] Test row-level security
- [ ] Create Metabase database connection
- [ ] Create Metabase group
- [ ] Create Metabase collection
- [ ] Set permissions
- [ ] Duplicate and reconfigure dashboard
- [ ] Verify agency users can access dashboard

______________________________________________________________________

**Previous:** [← Understanding the Data Flow](02-understanding-data-flow.md) | **Up:** [Documentation Home](../README.md)
