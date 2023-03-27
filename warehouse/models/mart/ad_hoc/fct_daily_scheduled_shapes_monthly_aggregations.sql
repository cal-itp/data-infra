{{ config(materialized='table') }}

WITH fct_daily_scheduled_shapes AS (
    SELECT * FROM
    {{ ref('fct_daily_scheduled_shapes') }}
    WHERE activity_date >= '2022-12-01' AND activity_date < '2023-01-01'

),

fct_daily_scheduled_shapes_monthly_aggregations AS (

    SELECT

        source_record_id,
        name,
        shape_id,
        route_id,
        route_short_name,
        month,
        year,
        n_trips,
        n_days

    FROM fct_daily_scheduled_shapes
    --GROUP BY BY 1,2,3,4

)

SELECT * FROM fct_daily_scheduled_shapes_monthly_aggregations
