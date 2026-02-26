---
name: New GTFS Feed for Payments Data Agency
about: Use this template to inform the data engineering team when an open-loop payments
  agency changes their GTFS feed
title: New GTFS Feed - Payments Agency
labels: project-payments
assignees: [charlie-costanzo, mrtopsyt]
---

## GTFS Feed Change Request

**Agency Name**:

- \[add agency name\]

**NEW GTFS Feed Name**:

- \[add feed name\]

### Acceptance Criteria

- The agency's new GTFS feed `source_record_id` from the `dim_gtfs_feeds` table has been substituted for the old `gtfs_dataset_source_record_id` in either `warehouse/seeds/payments_entity_mapping.csv` or `warehouse/seeds/payments_entity_mapping_enghouse.csv` (depending on which provider the agency uses)

### Notes

_Please enter any additional information that will facilitate the completion of this ticket. For example: Are there any remaining questions or concerns not mentioned above?_
