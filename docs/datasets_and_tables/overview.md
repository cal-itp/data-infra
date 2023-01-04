---
jupytext:
  cell_metadata_filter: -all
  formats: md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.10.3
kernelspec:
  display_name: Python 3 (ipykernel)
  language: python
  name: python3
---
(datasets-tables)=
# Datasets & Tables
In general, the [dbt docs site](https://dbt-docs.calitp.org/) should be the main
source of all documentation for warehouse entities (sources, views, tables,
"models", etc.) but the following pages contain some not-yet-migrated
documentation.

| page | description | datasets |
| ---- | ----------- | -------- |
| [Views](./views.md) | End-user friendly data for dashboards and metrics | E.g. `views.validation_*`, `views.reports_*`, `views.gtfs_schedule_*`, `views.payments_*`, `views.gtfs_rt_*`, `views.airtable_*`, `mart_transit_database.*`, `gtfs_schedule.*` |
| [Amplitude](./amplitude.md) | Data from Amplitude API for Benefits app | `amplitude.benefits_events `, `views.amplitude_benefits_events` |
| [GTFS-Schedule (Deprecated)](./gtfs_schedule.md) | GTFS Schedule data for the current day | `gtfs_schedule`, `gtfs_schedule_history.*`, `gtfs_schedule_type2.*`, `gtfs_views_staging.*` |
| [GTFS-Realtime (Deprecated)](gtfs-realtime) | GTFS Realtime data, collected every 20 seconds | `gtfs_rt.*`, `external_gtfs_rt.*`, `gtfs_rt_logs.*`, `staging.stg_rt__*` |
| [Transit Database](./transitdatabase.md) | A representation of Cal-ITP's internal knowledge about our Transit Operators in CA and various pieces of National Transit Database statistics for ease of use | `airtable.*`, `staging.transit_database__*`, `transitstacks.*` |
| [MST Payments](./mst_payments.md) | To-do | To-do |
