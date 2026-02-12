{{
    config(
        materialized='table',
        cluster_by='feed_key'
    )
}}

WITH dim_stop_arrivals AS (
    SELECT *
    FROM {{ ref('dim_stop_arrivals') }}
),

ordered_stops AS (
    SELECT
        feed_key,
        route_id,
        direction_id,
        stop_id,
        ROUND(AVG(stop_sequence), 1) AS avg_stop_seq

    FROM dim_stop_arrivals
    GROUP BY feed_key, route_id, direction_id, stop_id
)

SELECT * FROM ordered_stops
