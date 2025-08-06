{{
    config(
        materialized='incremental',
        incremental_strategy = 'insert_overwrite',
        partition_by={
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day'
        }, cluster_by=['base64_url']
    )
}}

WITH stop_time_updates AS (
    SELECT
        dt,
        service_date,
        base64_url,
        schedule_base64_url,
        trip_id,
        trip_start_date,
        trip_start_time,
        stop_id,
        stop_sequence,

        trip_update_timestamp,
        header_timestamp,
        _extract_ts, -- this is UTC
        arrival_time,
        departure_time,

    FROM `cal-itp-data-infra.mart_gtfs.fct_stop_time_updates`
    WHERE dt >= "2025-06-23" AND dt <= "2025-06-24" AND trip_id IS NOT NULL AND stop_id IS NOT NULL AND stop_sequence IS NOT NULL
)

SELECT * FROM stop_time_updates
