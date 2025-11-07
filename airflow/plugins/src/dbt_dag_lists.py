daily_audit_list = ["stg_audit__cloudaudit_googleapis_com_data_access+"]

daily_benefits_list = ["+fct_benefits_events"]

daily_gtfs_schedule_list = ["+fct_schedule_feed_downloads"]

daily_kuba_list = [
    "models/staging/kuba+",
    "models/intermediate/kuba+",
    "models/mart/kuba+",
]

manual_list = [
    "models/intermediate/gtfs/int_gtfs_rt__trip_updates_trip_stop_day_map_grouping.sql",
    "models/mart/gtfs/fct_stop_time_metrics.sql",
    "models/mart/gtfs/fct_stop_time_updates_sample.sql",
    "models/mart/gtfs/fct_trip_updates_stop_metrics.sql",
    "models/mart/gtfs/fct_trip_updates_trip_metrics.sql",
]

payments_list = [
    "models/staging/payments+",
    "models/intermediate/payments+",
    "models/mart/payments+",
]

gtfs_list = [
    "models/staging/gtfs+",
    "models/intermediate/gtfs+",
    "models/mart/gtfs+",
]
