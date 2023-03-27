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
        EXTRACT(month FROM activity_date) AS month,
        EXTRACT(year FROM activity_date) AS year,
        SUM(n_trips) AS n_trips,
        COUNT(*) AS n_days

    FROM fct_daily_scheduled_shapes
    GROUP BY 1, 2, 3, 4, 5, 6, 7

)

SELECT * FROM fct_daily_scheduled_shapes_monthly_aggregations
