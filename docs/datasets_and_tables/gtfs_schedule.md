# GTFS Schedule (WIP)

## Data

| dataset | dependent on | description |
| ------- | ----------- | ----------------|
| gtfs_downloader | | Downloads static GTFS Feeds. See the [GTFS static reference](https://developers.google.com/transit/gtfs/reference). |
| gtfs_schedule_history | | Latest warehouse data for GTFS Static feeds. See the [GTFS static reference](https://developers.google.com/transit/gtfs/reference). |
| gtfs_loader | gtfs_downloader, gtfs_schedule_history | Loads and parses the raw contents of downloaded GTFS feeds |
| gtfs_schedule_type2 | gtfs_loader | Analyzes the current day's result and creates data about any changes in feed contents. Tables with GTFS Static feeds across history (going back to April 15th, 2021). These are stored as type 2 slowly changing dimensions. They have `calitp_extracted_at`, and `calitp_deleted_at` fields. |
| gtfs_views_staging | gtfs_schedule_history2 | Creates staging tables for various view (Dimension and Fact) tables |
| gtfs_views | gtfs_views_staging | Creates view (Dimension and Fact) tables |

Please see [GTFS Schedule Quality Assessment Airflow pipelines](/airflow/static-schedule-pipeline) for more information.

## Dashboards

## Maintenance

### DAGs overview

### common issues

### backfilling
