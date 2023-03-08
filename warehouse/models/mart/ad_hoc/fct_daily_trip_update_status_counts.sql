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

WITH fct_stop_time_updates AS (
    SELECT * FROM {{ ref('int_gtfs_rt__trip_updates_no_stop_times') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_dt }}'))
    {% else %}
    WHERE dt >= {{ var('GTFS_RT_TU_START') }}
    {% endif %}
),

fct_daily_trip_update_status_counts AS (
    SELECT
        {{ dbt_utils.surrogate_key(['dt', 'base64_url', 'trip_schedule_relationship']) }} AS key,
        dt,
        base64_url,
        trip_schedule_relationship,
        gtfs_dataset_key,
        COUNT(DISTINCT trip_id) AS distinct_trip_ids,
    FROM fct_stop_time_updates
    GROUP BY 1, 2, 3, 4, 5
)

SELECT * FROM fct_daily_trip_update_status_counts
