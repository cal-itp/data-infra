{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by = {
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
    )
}}

{% if is_incremental() %}
    {% set dates = dbt_utils.get_column_values(table=this, column='dt', order_by = 'dt DESC', max_records = 1) %}
    {% set max_dt = dates[0] %}
{% endif %}

WITH

trip_updates AS (
    SELECT * FROM {{ ref('fct_trip_updates_messages') }}
    {% if is_incremental() %}
    WHERE dt >= '{{ max_dt }}'
    {% else %}
    WHERE dt >= {{ var('GTFS_RT_START') }}
    {% endif %}
),

int_gtfs_rt__trip_updates_no_stop_times AS (
    SELECT * EXCEPT (stop_time_updates)
    FROM trip_updates
)

SELECT * FROM int_gtfs_rt__trip_updates_no_stop_times
