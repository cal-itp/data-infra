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

WITH vehicle_positions AS (
    SELECT * FROM {{ ref('fct_vehicle_positions_messages') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >= {{ var('GTFS_RT_START') }}
    {% endif %}
),

int_gtfs_rt__vehicle_positions_trip_summaries AS (
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
        MIN(_extract_ts) AS min_extract_ts,
        MAX(_extract_ts) AS max_extract_ts,
        MIN(header_timestamp) AS min_header_timestamp,
        MAX(header_timestamp) AS max_header_timestamp,
        MIN(vehicle_timestamp) AS min_vehicle_timestamp,
        MAX(vehicle_timestamp) AS max_vehicle_timestamp,
        ARRAY_AGG(position_latitude ORDER BY _extract_ts)[OFFSET(0)] AS first_position_latitude,
        ARRAY_AGG(position_longitude ORDER BY _extract_ts)[OFFSET(0)] AS first_position_longitude,
        ARRAY_AGG(position_latitude ORDER BY _extract_ts DESC)[OFFSET(0)] AS last_position_latitude,
        ARRAY_AGG(position_longitude ORDER BY _extract_ts DESC)[OFFSET(0)] AS last_position_longitude,
    FROM vehicle_positions
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8 --noqa: L054
)

SELECT * FROM int_gtfs_rt__vehicle_positions_trip_summaries
