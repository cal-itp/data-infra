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

# Datasets and Tables (WIP)

| page | description | datasets |
| ---- | ----------- | -------- |
| [GTFS Schedule](./gtfs_schedule.md) | GTFS Schedule data for the current day | `gtfs_schedule`, `gtfs_schedule_history`, `gtfs_schedule_type2` |
| [MST Payments](./mst_payments.md) | TODO | TODO |
| [Transitstacks](./transitdatabase.md) | A representation of Cal-ITPs internal knowledge about our Transit Operators in CA and various pieces of National Transit Database statistics for ease of use | `transitstacks`, `views.transitstacks` |
| [Views](./views.md) | End-user friendly data for dashboards and metrics | E.g. `views.validation_*`, `views.gtfs_schedule_*` |
