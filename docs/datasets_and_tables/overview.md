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
| [Transit Database](./transitdatabase.md) | A representation of Cal-ITP's internal knowledge about our Transit Operators in CA and various pieces of National Transit Database statistics for ease of use | `airtable.*`, `staging.transit_database__*`, `transitstacks.*` |
| [MST Payments](./mst_payments.md) | To-do | To-do |
