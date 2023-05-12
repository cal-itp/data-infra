{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by = {
        'field': 'dt',
        'data_type': 'date',
        'granularity': 'day',
    },
    cluster_by = 'base64_url'
) }}

WITH int_gtfs_rt__service_alerts_fully_unnested AS (
    SELECT * FROM {{ ref('int_gtfs_rt__service_alerts_fully_unnested') }}
    WHERE {{ gtfs_rt_dt_where() }}
),

select_english AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY
            service_alert_message_key,
            active_period_start,
            active_period_end,
            agency_id,
            route_id,
            direction_id,
            trip_id,
            trip_start_date,
            trip_start_time,
            stop_id
            ORDER BY english_likelihood DESC, header_text_language ASC) AS english_rank
    FROM int_gtfs_rt__service_alerts_fully_unnested
    QUALIFY english_rank = 1
),

fct_service_alerts_messages_unnested AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'service_alert_message_key',
            'active_period_start',
            'active_period_end',
            'agency_id',
            'route_id',
            'direction_id',
            'trip_id',
            'trip_start_date',
            'trip_start_time',
            'stop_id']) }} AS key,
        service_alert_message_key,
        gtfs_dataset_key,
        dt,
        hour,
        _extract_ts,
        header_timestamp,
        base64_url,
        _config_extract_ts,
        _gtfs_dataset_name,
        _header_message_age,
        header_version,
        header_incrementality,
        id,
        cause,
        effect,

        -- active periods
        active_period_start,
        active_period_end,
        -- per spec, start/end is +/- infinity if null: https://gtfs.org/realtime/reference/#message-timerange
        -- use placeholders instead
        COALESCE(TIMESTAMP_SECONDS(active_period_start), TIMESTAMP(DATE(1900,1,1))) AS active_period_start_ts,
        COALESCE(TIMESTAMP_SECONDS(active_period_end), TIMESTAMP(DATE(2099,1,1))) AS active_period_end_ts,

        -- informed entities
        agency_id,
        route_id,
        route_type,
        direction_id,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        trip_schedule_relationship,
        stop_id,

        -- text (translations)
        header_text_text,
        header_text_language,

        description_text_text,
        description_text_language,

        tts_header_text_text,
        tts_header_text_language,

        tts_description_text_text,
        tts_description_text_language,

        url_text,
        url_language
    FROM select_english
)

SELECT * FROM fct_service_alerts_messages_unnested
