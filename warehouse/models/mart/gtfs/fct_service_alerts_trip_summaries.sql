{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
    )
}}

{% if is_incremental() %}
    {% set timestamps = dbt_utils.get_column_values(table=this, column='dt', order_by = 'dt DESC', max_records = 1) %}
    {% set max_ts = timestamps[0] %}
{% endif %}

WITH service_alerts AS (
    SELECT * FROM {{ ref('fct_service_alert_informed_entities') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >= {{ var('GTFS_RT_START') }}
    {% endif %}
),

fct_service_alerts_trip_summaries AS (
    SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        {{ dbt_utils.generate_surrogate_key([
            'dt',
            'base64_url',
            'trip_id',
            'trip_route_id',
            'trip_direction_id',
            'trip_start_time',
            'trip_start_date',
        ]) }} as key,
        dt,
        base64_url,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        COUNT(DISTINCT id) AS num_distinct_message_ids,
        ARRAY_AGG(DISTINCT service_alert_message_key) AS service_alert_message_keys,
        MIN(_extract_ts) AS min_extract_ts,
        MAX(_extract_ts) AS max_extract_ts,
        MIN(header_timestamp) AS min_header_timestamp,
        MAX(header_timestamp) AS max_header_timestamp,
    FROM service_alerts
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
)

SELECT * FROM fct_service_alerts_trip_summaries
