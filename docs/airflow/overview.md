# Airtable

## Primary Keys

Airtable forces the use of the left-most field as the primary key of the database: the field that must be referenced in other tables, similar to a VLOOKUP in a spreadsheet. Unlike many databases, Airtable doesn't enforce uniqueness in the values of the primary key field.  Instead, it assigns it an underlying and mostly hidden unique [`RECORD ID`](https://support.airtable.com/hc/en-us/articles/360051564873-Record-ID), which can be exposed by creating a formula field to reference it.

For the sake of this documentation, we've noted the [`Primary Field`](https://support.airtable.com/hc/en-us/articles/202624179-The-primary-field), which is not guaranteed to be unique. Some tables additionally expose the unique [`RECORD ID`](https://support.airtable.com/hc/en-us/articles/360051564873-Record-ID) as well.

## Full Documentation of Fields

AirTable does not currently have an effective mechanism to programmaticaly download your data schema (they have currently paused issuing keys to their metadata API). Rather than manually type-out and export each individual field definition from AirTable, please see the [AirTable-based documentation of fields](https://airtable.com/appPnJWrQ7ui4UmIl/api/docs) which is produced as a part of their API documentation. Note that you must be authenticated with access to the base to reach this link.

## Related Data

The data in the Airtable Transit Database is distinct but related to the following data:

- [GTFS Schedule Quality Assessment Airflow pipelines](/airflow/static-schedule-pipeline) results in the [warehouse](/warehouse/overview)
- [GTFS Schedules Datasets](datasets_and_tables/gtfs_schedule)

Currently neither of the above processes or datasets either rely on or contribute back to the Airflow Transit Database – this is a work in progress.  Rather, they rely on the list of transit datasets in the file [`agencies.yml`](https://github.com/cal-itp/data-infra/tree/main/airflow/data/agencies.yml) to dictate what datasets to download and assess.
