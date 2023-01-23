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
    {% set timestamps = dbt_utils.get_column_values(table=this, column='dt', order_by = 'dt, DESC', max_records = 1) %}
    {% set max_ts = timestamps[0] %}
{% endif %}

WITH vehicle_positions AS (
    SELECT * FROM {{ ref('fct_vehicle_positions_messages') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('TRIP_UPDATES_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

int_gtfs_rt__vehicle_positions_trip_summaries AS (
    SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        {{ dbt_utils.surrogate_key([
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
        MIN(vehicle_timestamp) AS min_trip_update_timestamp,
        MAX(vehicle_timestamp) AS max_trip_update_timestamp,
    FROM vehicle_positions
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
)

SELECT * FROM int_gtfs_rt__vehicle_positions_trip_summaries
