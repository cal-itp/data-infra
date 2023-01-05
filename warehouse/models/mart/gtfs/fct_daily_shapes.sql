{{ config(materialized='table') }}

WITH fct_daily_scheduled_trips AS (

    SELECT *
    FROM {{ ref('fct_daily_scheduled_trips') }}

),

fct_daily_shapes AS (

    SELECT

        COUNT(DISTINCT trip_key) AS n_trips,
        feed_key,
        service_date,
        shape_array_key

    FROM fct_daily_scheduled_trips
    GROUP BY feed_key, service_date, shape_array_key

)

SELECT * FROM fct_daily_shapes


-- WITH fct_daily_scheduled_trips AS (

--     SELECT *
--     FROM `cal-itp-data-infra-staging`.`charlie_mart_gtfs`.`fct_daily_scheduled_trips`

-- ),

-- dim_shapes_arrays AS (

--     SELECT *
--     FROM `cal-itp-data-infra-staging`.`charlie_mart_gtfs`.`dim_shapes_arrays`

-- ),

-- trips_counted AS (

--     SELECT

--         COUNT(DISTINCT trip_key) AS n_trips,
--         feed_key,
--         service_date,
--         shape_array_key

--     FROM fct_daily_scheduled_trips
--     GROUP BY feed_key, service_date, shape_array_key

-- ),

-- fct_daily_shapes AS (

--   SELECT
--     trips_counted.*,
--     dim_shapes_arrays.pt_array

--   FROM trips_counted
--   LEFT JOIN dim_shapes_arrays
--     ON trips_counted.shape_array_key = dim_shapes_arrays.key
-- )

-- SELECT * FROM fct_daily_shapes
