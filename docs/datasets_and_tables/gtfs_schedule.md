# GTFS Schedule

## Warehouse Schemas

### Source

| dataset name | description |
| ------- | ----------- |
| `gtfs_schedule_type2` | Tables with GTFS-Static feeds across history (going back to April 15 2021). These are stored as type 2 slowly changing dimensions. They have `calitp_extracted_at` and `calitp_deleted_at` fields. |
| `gtfs_schedule_history` | Data in the `gtfs_schedule_history` dataset in BigQuery |

### Staging

| dataset name | description |
| ------- | ----------- |
| `gtfs_schedule` | Latest warehouse data for GTFS-Schedule feeds. |

### See Also
The [GTFS-Schedule Data Standard](https://developers.google.com/transit/gtfs/).

## dbt Project Directories ([More information on the project-perspective](navigating-dbt-docs))

### Source tables
| Directory name |
| ------- |
| `gtfs_schedule_history` |
| `gtfs_type2` |

### Staging tables
| Directory name |
| ------- |
| `gtfs_schedule_latest_only` |

:::{admonition} See Also: `views` documentation
:class: tip
This section contains documentation for `source` and `staging` tables only. For documentation on GTFS Schedule `views`, [visit this link](view-models).
:::
