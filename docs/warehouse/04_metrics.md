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

# Metric Views (WIP)

A metric table (or view) is a table that calculates meaningful measures across time.
It is defined by the three pieces below.

* **The grain**: the business process that each row represents.
* **Metric date columns**.
    * `metric_date`: the day the metric describes.
    * `metric_period`: the period of time the metric spans (e.g. day for a metric
      that describes data across a single day; week for when `metric_date` describes data across a week.)
* **Metric value columns**

## Example: views.validation_code_metrics

The `views.validation_code_metrics` table contains a count of each validator code triggered per GTFS Static data feed in the warehouse.

| component | description |
| --------- | ----------- |
| grain | One row per GTFS Static feed (e.g. an agency's data), per validator code. |
| metric date columns | Calculated for every day with daily periods. Note that `metric_period` is omitted, but should be set to "day". |
| metric values | The column `n_notices` counts the number of notices per code. |
