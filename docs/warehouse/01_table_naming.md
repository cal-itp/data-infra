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

# Table Naming
The warehouse puts tables that are ready for end-users into the [`views` dataset](/datasets_and_tables/views/).
They are named using a convention loosely based off of the Kimball method for modeling data,
which separates data into underlying dimensions (measurements) and facts (calculations).

Tables should be named using the following convention: `{domain}_{table_type}_{details}`.

For example, take `gtfs_schedule_dim_feeds`:

* The domain is `gtfs_schedule`.
* The table type is `dim` for dimension.
* The details are that it's about `feeds`.

There are for common fact table types names currently used in the warehouse:

* fact_daily_* - facts for some dimension represented every day.
* fact_index_* - a "bridge" table, which can be used to reconstruct data on a given day.
  For example, gtfs_schedule_fact_index_feed_trip_stops, lets people reconstruct a big join
  between feeds, trips, stop_times, and stops for any day. This requires filtering on
  calitp_extracted_at and calitp_deleted_at, then joining on each dimensional key (e.g. feed_key).
* data_* - a bridge table that has been filtered and joined on dimensional keys for a given date.
