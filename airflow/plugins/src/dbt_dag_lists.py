# DAG: dbt_manual
manual_list = [
    "models/intermediate/gtfs/int_gtfs_rt__trip_updates_trip_stop_day_map_grouping.sql",
    "models/mart/gtfs/fct_stop_time_metrics.sql",
    "models/mart/gtfs/fct_stop_time_updates_sample.sql",
    "models/mart/gtfs/fct_trip_updates_stop_metrics.sql",
    "models/mart/gtfs/fct_trip_updates_trip_metrics.sql",
]

# DAG: dbt_daily
daily_gtfs_schedule_list = ["+fct_schedule_feed_downloads"]

# DAG: dbt_daily and dbt_all
audit_list = [
    "models/staging/audit",
    "models/mart/audit",
]

benefits_list = [
    "models/staging/amplitude",
    "models/mart/benefits",
]

kuba_list = [
    "models/staging/kuba",
    "models/intermediate/kuba",
    "models/mart/kuba",
]

payments_list = [
    "models/staging/payments",
    "models/intermediate/payments",
    "models/mart/payments",
]

# DAG: dbt_all
gtfs_list = [
    "models/staging/gtfs",
    "models/staging/rt",
    "models/intermediate/gtfs",
    "models/mart/gtfs",
]

gtfs_quality_list = [
    "models/staging/gtfs_quality",
    "models/intermediate/gtfs_quality",
    "models/mart/gtfs_quality",
]

gtfs_rollup_list = [
    "models/mart/gtfs_rollup",
]

gtfs_schedule_latest_list = [
    "models/mart/gtfs_schedule_latest",
]

ntd_list = [
    "models/staging/ntd_annual_reporting",
    "models/staging/ntd_assets",
    "models/staging/ntd_funding_and_expenses",
    "models/staging/ntd_ridership",
    "models/staging/ntd_safety_and_security",
    "models/intermediate/ntd_annual_reporting",
    "models/intermediate/ntd_assets",
    "models/intermediate/ntd_funding_and_expenses",
    "models/mart/ntd",
    "models/mart/ntd_annual_reporting",
    "models/mart/ntd_assets",
    "models/mart/ntd_funding_and_expenses",
    "models/mart/ntd_ridership",
    "models/mart/ntd_safety_and_security",
]

ntd_validation_list = [
    "models/staging/ntd_validation",
    "models/intermediate/ntd_validation",
    "models/mart/ntd_validation",
]

state_geoportal_list = [
    "models/staging/state_geoportal",
]

transit_database_list = [
    "models/staging/transit_database",
    "models/intermediate/transit_database",
    "models/mart/transit_database",
    "models/mart/transit_database_latest",
]
