---
name: New Payments Agency Onboarding
about: Use this template to kick off onboarding a new open-loop payments agency
title: New Payments Agency Onboarding - [Agency Name]
labels: project-payments
assignees: [mrtopsyt, csuyat-dot, amandaha8]
---

## Agency Information

**Agency Name**:

- \[add agency name\]

**GTFS Feed Name / Identifier**:

- \[add feed name as it appears in the transit database - find it in the "Name" column under "gtfs datasets" in Airtable\]

**Organization Name** _(as it appears in the transit database)_:

- \[add organization name - find it in the "Name" column under "organizations" in Airtable \]

**Fare Processor Vendor**:

- [ ] Littlepay
- [ ] Enghouse

**Contact for questions / when ticket is complete**:

- \[add name\]
- \[add email or other contact method\]

______________________________________________________________________

## Littlepay

_Complete this section if the agency uses Littlepay. Leave blank otherwise._

**Participant ID**:

- \[e.g. `mst`, `clean-air-express`\]

**AWS Credentials and S3 Bucket**:

- Littlepay will provide the AWS access key and S3 bucket/prefix ahead of launch. Confirm this has been shared before closing this ticket.

______________________________________________________________________

## Enghouse

_Complete this section if the agency uses Enghouse. Leave blank otherwise._

**Operator ID** _(provided by Enghouse)_:

- \[add\]

______________________________________________________________________

## Elavon

**Elavon Customer Name** _(as it appears in Elavon data)_:

- \[add\]

______________________________________________________________________

### Notes

_Any additional context or open questions?_

______________________________________________________________________

### Definition of Done

- [ ] Entity mapping, service account, row access policy have been set up for the agency
- [ ] A database has been created in Metabase and permissions have been assigned appropriatley
- [ ] Analysts have been notified and an issue has been created in data-analyses to create dashboards
