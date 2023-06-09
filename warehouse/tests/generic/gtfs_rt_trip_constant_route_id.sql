{% test gtfs_rt_trip_constant_route_id(model) %}

-- test that a given trip in RT service alerts data is only associated with one route id
WITH grouped AS (
    SELECT *
    FROM {{ model }}
),

window_functions AS (
    SELECT DISTINCT
        key,
        FIRST_VALUE(trip_route_id)
            OVER (
                PARTITION BY key
                ORDER BY min_header_timestamp
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS starting_route_id,
        LAST_VALUE(trip_route_id)
            OVER (
                PARTITION BY key
                ORDER BY max_header_timestamp
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS ending_route_id,
    FROM grouped
),

bad_rows AS (
    SELECT
        key,
        starting_route_id,
        ending_route_id,
    FROM window_functions
    WHERE starting_route_id != ending_route_id
)

SELECT * FROM bad_rows

{% endtest %}
