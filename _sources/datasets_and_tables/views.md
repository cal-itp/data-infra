# Views (WIP)

## Data

|Table                                                    |Description|Link                                                                                                                         |
|---------------------------------------------------------|-----------|-----------------------------------------------------------------------------------------------------------------------------|
|dim_date                                                 |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.dim_date)                                                 |
|dim_metric_date                                          |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.dim_metric_date)                                          |
|gtfs_rt_fact_daily_feeds                                 |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_rt_fact_daily_feeds)                                 |
|gtfs_rt_fact_daily_validation_errors                     |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_rt_fact_daily_validation_errors)                     |
|gtfs_rt_fact_extraction_errors                           |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_rt_fact_extraction_errors)                           |
|gtfs_rt_fact_files                                       |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_rt_fact_files)                                       |
|gtfs_rt_fact_files_wide_hourly                           |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_rt_fact_files_wide_hourly)                           |
|gtfs_rt_validation_code_descriptions                     |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_rt_validation_code_descriptions)                     |
|gtfs_schedule_data_feed_trip_stops_latest                |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_data_feed_trip_stops_latest)                |
|gtfs_schedule_dim_feeds                                  |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_dim_feeds)                                  |
|gtfs_schedule_dim_files                                  |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_dim_files)                                  |
|gtfs_schedule_dim_pathways                               |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_dim_pathways)                               |
|gtfs_schedule_dim_routes                                 |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_dim_routes)                                 |
|gtfs_schedule_dim_shapes                                 |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_dim_shapes)                                 |
|gtfs_schedule_dim_shapes_geo                             |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_dim_shapes_geo)                             |
|gtfs_schedule_dim_shapes_geo_latest                      |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_dim_shapes_geo_latest)                      |
|gtfs_schedule_dim_stop_times                             |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_dim_stop_times)                             |
|gtfs_schedule_dim_stops                                  |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_dim_stops)                                  |
|gtfs_schedule_dim_trips                                  |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_dim_trips)                                  |
|gtfs_schedule_fact_daily                                 |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_fact_daily)                                 |
|gtfs_schedule_fact_daily_feed_files                      |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_fact_daily_feed_files)                      |
|gtfs_schedule_fact_daily_feed_routes                     |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_fact_daily_feed_routes)                     |
|gtfs_schedule_fact_daily_feed_stops                      |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_fact_daily_feed_stops)                      |
|gtfs_schedule_fact_daily_feeds                           |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_fact_daily_feeds)                           |
|gtfs_schedule_fact_daily_pathways                        |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_fact_daily_pathways)                        |
|gtfs_schedule_fact_daily_service                         |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_fact_daily_service)                         |
|gtfs_schedule_fact_daily_trips                           |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_fact_daily_trips)                           |
|gtfs_schedule_fact_day_of_week_service_monthly_comparison|           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_fact_day_of_week_service_monthly_comparison)|
|gtfs_schedule_fact_route_id_changes                      |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_fact_route_id_changes)                      |
|gtfs_schedule_fact_stop_id_changes                       |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_fact_stop_id_changes)                       |
|gtfs_schedule_index_feed_trip_stops                      |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_index_feed_trip_stops)                      |
|gtfs_schedule_stg_calendar_long                          |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_stg_calendar_long)                          |
|gtfs_schedule_stg_daily_service                          |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_schedule_stg_daily_service)                          |
|reports_gtfs_schedule_index                              |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.reports_gtfs_schedule_index)                              |
|reports_weekly_file_checks                               |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.reports_weekly_file_checks)                               |
|validation_code_descriptions                             |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.validation_code_descriptions)                             |
|validation_dim_codes                                     |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.validation_dim_codes)                                     |
|validation_fact_daily_feed_codes                         |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.validation_fact_daily_feed_codes)                         |
|validation_fact_daily_feed_notices                       |           |[link](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.validation_fact_daily_feed_notices)                       |
