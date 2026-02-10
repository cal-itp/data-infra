# Documentation Migration Guide

**Purpose:** Guide for transitioning from old payments documentation to new Diátaxis-aligned structure\
**Date:** January 2026\
**Status:** In Progress

## Overview

The Cal-ITP payments ecosystem documentation has been reorganized according to the [Diátaxis framework](https://diataxis.fr/), which separates documentation into four distinct categories based on user needs:

- **Tutorials** - Learning-oriented lessons
- **How-To Guides** - Task-oriented instructions
- **Reference** - Information-oriented technical descriptions
- **Explanation** - Understanding-oriented discussions

## What's Changed

### Old Structure

```
runbooks/workflow/payments/
├── 1-create-and-maintain-littlepay-data-syncs.md
└── 2-add-agency-metabase-data-source-and-dashboards.md
```

### New Structure

```
runbooks/workflow/payments/
├── README.md (main index)
├── MIGRATION_GUIDE.md (this file)
├── tutorials/
│   ├── 01-getting-started.md
│   ├── 02-understanding-data-flow.md
│   └── 03-first-agency-onboarding.md
├── how-to/
│   ├── onboard-littlepay-agency.md
│   ├── onboard-elavon-agency.md
│   ├── create-metabase-dashboards.md
│   ├── rotate-littlepay-keys.md
│   ├── troubleshoot-sync-issues.md
│   ├── monitor-pipeline-health.md
│   └── update-row-access-policies.md
├── reference/
│   ├── architecture.md
│   ├── littlepay-schema.md
│   ├── elavon-schema.md
│   ├── dbt-models.md
│   ├── airflow-dags.md
│   ├── service-accounts.md
│   ├── gcs-buckets.md
│   ├── metabase-config.md
│   └── api-endpoints.md
└── explanation/
    ├── ecosystem-overview.md
    ├── why-diataxis.md
    ├── data-security.md
    ├── vendor-integration.md
    ├── fare-types.md
    ├── settlement-reconciliation.md
    └── design-decisions.md
```

## Content Mapping

### Old Document → New Location(s)

#### `1-create-and-maintain-littlepay-data-syncs.md`

This document has been split and enhanced:

| Old Section                      | New Location                                     | Status      |
| -------------------------------- | ------------------------------------------------ | ----------- |
| Setting Up a New Littlepay Sync  | `how-to/onboard-littlepay-agency.md`             | ✅ Complete |
| Prerequisites                    | `how-to/onboard-littlepay-agency.md` (Step 1)    | ✅ Complete |
| First-Time Setup Steps           | `how-to/onboard-littlepay-agency.md` (Steps 2-4) | ✅ Complete |
| Rotating Littlepay AWS Keys      | `how-to/rotate-littlepay-keys.md`                | ✅ Complete |
| Create and store new credentials | `how-to/rotate-littlepay-keys.md` (Steps 1-2)    | ✅ Complete |
| Disable old credentials          | `how-to/rotate-littlepay-keys.md` (Step 4)       | ✅ Complete |
| Delete old credentials           | `how-to/rotate-littlepay-keys.md` (Step 6)       | ✅ Complete |

**Enhancements:**

- Added detailed verification steps
- Included troubleshooting sections
- Added rollback procedures
- Included checklists and tracking templates

#### `2-add-agency-metabase-data-source-and-dashboards.md`

This document has been reorganized and enhanced:

| Old Section                     | New Location                                       | Status      |
| ------------------------------- | -------------------------------------------------- | ----------- |
| Add a New Agency Data Source    | `how-to/create-metabase-dashboards.md` (Steps 1-3) | ✅ Complete |
| Create a new service account    | `how-to/onboard-littlepay-agency.md` (Step 2)      | ✅ Complete |
| Create a new row access policy  | `how-to/onboard-littlepay-agency.md` (Step 4)      | ✅ Complete |
| Add a new Database in Metabase  | `how-to/create-metabase-dashboards.md` (Step 1)    | ✅ Complete |
| Create a New Agency Dashboard   | `how-to/create-metabase-dashboards.md` (Steps 4-6) | ✅ Complete |
| Duplicate an existing dashboard | `how-to/create-metabase-dashboards.md` (Step 4)    | ✅ Complete |
| Re-configuring questions        | `how-to/create-metabase-dashboards.md` (Step 5)    | ✅ Complete |
| Configure dashboard filters     | `how-to/create-metabase-dashboards.md` (Step 6)    | ✅ Complete |
| Diagram: row-based security     | `how-to/create-metabase-dashboards.md` (bottom)    | ✅ Complete |

**Enhancements:**

- Separated service account creation from Metabase setup
- Added detailed verification steps
- Included comprehensive troubleshooting
- Added security verification procedures
- Enhanced diagrams and visual aids

## New Content Added

### Tutorials (Learning-Oriented)

These are entirely new and provide guided learning experiences:

1. **Getting Started** - Introduction to the payments ecosystem

   - System components overview
   - Following a transaction through the pipeline
   - Verification procedures
   - Key resources

2. **Understanding the Data Flow** - Deep dive into data pipeline

   - Vendor data structures
   - Sync and parse processes
   - External tables and dbt transformations
   - Hands-on exercises

3. **Your First Agency Onboarding** - Complete walkthrough

   - Fictional agency scenario
   - Step-by-step guidance
   - Common pitfalls
   - Troubleshooting tips

### Reference Documentation (To Be Created)

Technical specifications and detailed information:

- **Architecture** - System architecture diagrams and descriptions
- **Littlepay Schema** - Complete data schema documentation
- **Elavon Schema** - Complete data schema documentation
- **dbt Models** - Model-by-model reference
- **Airflow DAGs** - DAG configurations and schedules
- **Service Accounts** - Complete list with permissions
- **GCS Buckets** - Bucket purposes and structures
- **Metabase Config** - Configuration reference
- **API Endpoints** - Integration points

### Explanation Documentation (To Be Created)

Conceptual understanding and context:

- **Ecosystem Overview** - High-level system understanding
- **Why Diátaxis** - Documentation framework rationale
- **Data Security** - Security model and row-level access
- **Vendor Integration** - Integration patterns and approaches
- **Fare Types** - Fare calculation concepts
- **Settlement & Reconciliation** - Financial processes
- **Design Decisions** - Architectural choices and trade-offs

## How to Use the New Documentation

### For New Team Members

**Start here:**

1. Read [README.md](README.md) for overview
2. Complete [Getting Started Tutorial](tutorials/01-getting-started.md)
3. Read [Payments Ecosystem Overview](explanation/ecosystem-overview.md) (when available)
4. Review [Data Pipeline Architecture](reference/architecture.md) (when available)

### For Onboarding a New Agency

**Follow this path:**

1. Review [Understanding the Data Flow](tutorials/02-understanding-data-flow.md)
2. Use [Onboard a New Littlepay Agency](how-to/onboard-littlepay-agency.md)
3. Use [Create Agency Metabase Dashboards](how-to/create-metabase-dashboards.md)
4. Optionally: [Your First Agency Onboarding Tutorial](tutorials/03-first-agency-onboarding.md) for learning

### For Maintenance Tasks

**Use how-to guides:**

- [Rotate Littlepay AWS Keys](how-to/rotate-littlepay-keys.md)
- [Troubleshoot Data Sync Issues](how-to/troubleshoot-sync-issues.md) (to be created)
- [Monitor Pipeline Health](how-to/monitor-pipeline-health.md) (to be created)
- [Update Row Access Policies](how-to/update-row-access-policies.md) (to be created)

### For Understanding the System

**Read explanations:**

- [Payments Ecosystem Overview](explanation/ecosystem-overview.md) (to be created)
- [Data Security & Row-Level Access](explanation/data-security.md) (to be created)
- [Vendor Integration Patterns](explanation/vendor-integration.md) (to be created)
- [Design Decisions & Trade-offs](explanation/design-decisions.md) (to be created)

### For Technical Details

**Consult reference docs:**

- [Littlepay Data Schema](reference/littlepay-schema.md) (to be created)
- [dbt Models Reference](reference/dbt-models.md) (to be created)
- [Airflow DAGs Reference](reference/airflow-dags.md) (to be created)
- [Service Accounts & Permissions](reference/service-accounts.md) (to be created)

## What to Do with Old Documents

### Recommended Approach

**Option 1: Archive (Recommended)**

1. Create `runbooks/workflow/payments/archive/` directory
2. Move old documents there with date prefix:
   - `archive/2024-01-27_1-create-and-maintain-littlepay-data-syncs.md`
   - `archive/2024-01-27_2-add-agency-metabase-data-source-and-dashboards.md`
3. Add `DEPRECATED.md` file in archive explaining the migration

**Option 2: Add Deprecation Notices**

1. Keep old files in place temporarily
2. Add prominent notice at top of each:
   ```markdown
   > **⚠️ DEPRECATED:** This documentation has been reorganized. 
   > See the [Migration Guide](MIGRATION_GUIDE.md) for new locations.
   ```
3. Remove after transition period (e.g., 3-6 months)

**Option 3: Delete**

1. Delete old files immediately
2. All content has been migrated and enhanced
3. Git history preserves old versions if needed

## Updating Links

### Internal Links to Update

Search the codebase for links to old documentation:

```bash
# Find references to old docs
grep -r "1-create-and-maintain-littlepay-data-syncs" .
grep -r "2-add-agency-metabase-data-source-and-dashboards" .
```

Update links in:

- [ ] Other runbook documents
- [ ] README files
- [ ] Code comments
- [ ] Airflow DAG descriptions
- [ ] dbt model documentation
- [ ] Wiki pages
- [ ] Confluence pages
- [ ] Slack channel descriptions

### External Links

If old documentation URLs were shared externally:

- Update bookmarks
- Update training materials
- Notify team members
- Update onboarding checklists

## Completion Status

### ✅ Completed

- [x] Main README with Diátaxis structure
- [x] Tutorial: Getting Started
- [x] Tutorial: Understanding Data Flow
- [x] Tutorial: First Agency Onboarding
- [x] How-To: Onboard Littlepay Agency
- [x] How-To: Create Metabase Dashboards
- [x] How-To: Rotate Littlepay Keys
- [x] Migration Guide (this document)

### 🔄 In Progress

- [ ] How-To: Onboard Elavon Agency
- [ ] How-To: Troubleshoot Data Sync Issues
- [ ] How-To: Monitor Pipeline Health
- [ ] How-To: Update Row Access Policies

### 📋 Planned

**Reference Documentation:**

- [ ] Architecture
- [ ] Littlepay Schema
- [ ] Elavon Schema
- [ ] dbt Models
- [ ] Airflow DAGs
- [ ] Service Accounts
- [ ] GCS Buckets
- [ ] Metabase Configuration
- [ ] API Endpoints

**Explanation Documentation:**

- [ ] Ecosystem Overview
- [ ] Why Diátaxis
- [ ] Data Security & Row-Level Access
- [ ] Vendor Integration Patterns
- [ ] Fare Types & Calculations
- [ ] Settlement & Reconciliation
- [ ] Design Decisions & Trade-offs

## Benefits of New Structure

### For Users

1. **Easier to Find Information**

   - Clear categorization by purpose
   - Consistent structure across all docs
   - Better navigation and cross-linking

2. **Better Learning Experience**

   - Tutorials for newcomers
   - Task-focused how-to guides
   - Conceptual explanations when needed

3. **More Comprehensive**

   - Covers end-to-end ecosystem
   - Includes troubleshooting
   - Provides context and rationale

### For Maintainers

1. **Easier to Update**

   - Clear place for each type of content
   - Less duplication
   - Modular structure

2. **Easier to Expand**

   - Framework for adding new content
   - Consistent patterns to follow
   - Clear guidelines

3. **Better Quality**

   - Each document has clear purpose
   - Appropriate level of detail
   - Consistent formatting

## Questions or Issues?

If you have questions about the new documentation structure:

1. Review the [Diátaxis framework](https://diataxis.fr/)
2. Check the [main README](README.md)
3. Reach out to the data infrastructure team
4. Create an issue in the data-infra repository

## Contributing

When adding new documentation:

1. **Determine the type:**

   - Learning something? → Tutorial
   - Accomplishing a task? → How-To Guide
   - Looking up information? → Reference
   - Understanding concepts? → Explanation

2. **Follow the patterns:**

   - Review existing docs in that category
   - Use consistent formatting
   - Include appropriate metadata (time, prerequisites, etc.)

3. **Update the main README:**

   - Add links to new documents
   - Keep the index current

4. **Cross-link appropriately:**

   - Link to related documents
   - Provide navigation aids
   - Help users find what they need

______________________________________________________________________

**Last Updated:** January 27, 2026\
**Status:** Documentation migration in progress\
**Next Review:** After all planned documents are created
