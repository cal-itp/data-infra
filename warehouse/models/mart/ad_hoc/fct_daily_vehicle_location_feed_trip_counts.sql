{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by = {
        'field': 'dt',
        'data_type': 'date',
        'granularity': 'day',
    },
) }}

{% if is_incremental() %}
    {% set dates = dbt_utils.get_column_values(table=this, column='dt', order_by = 'dt DESC', max_records = 1) %}
    {% set max_dt = dates[0] %}
{% endif %}

WITH fct_vehicle_locations AS (
    SELECT * FROM {{ ref('fct_vehicle_locations') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_dt }}'))
    {% else %}
    WHERE dt >= {{ var('GTFS_RT_START') }}
    {% endif %}
),

fct_daily_vehicle_location_trip_counts AS (
    SELECT
        {{ dbt_utils.surrogate_key(['dt', 'base64_url']) }} AS key,
        dt,
        gtfs_dataset_key,
        base64_url,
        COUNT(DISTINCT trip_id) AS distinct_trips_observed
    FROM fct_vehicle_locations
    GROUP BY dt, gtfs_dataset_key, base64_url
)

SELECT * FROM fct_daily_vehicle_location_trip_counts
