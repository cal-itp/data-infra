# GTFS Schedule (WIP)

## Data

| dataset | description |
| ------- | ----------- |
| gtfs_schedule | Latest warehouse data for GTFS Static feeds. See the [GTFS static reference](https://developers.google.com/transit/gtfs/reference). |
| gtfs_schedule_type2 | Tables with GTFS Static feeds across history (going back to April 15th, 2021). These are stored as type 2 slowly changing dimensions. They have `calitp_extracted_at`, and `calitp_deleted_at` fields. |
| (internal) gtfs_schedule_history | External tables with all new feed data across history. |

## Dashboards

## Maintenance

### DAGs overview

### common issues

### backfilling
