WITH dim_stop_times AS (

    SELECT * FROM {{ ref('dim_stop_times') }}

),

dim_trips AS (

    SELECT * FROM {{ ref('dim_trips') }}

),

trip_id_summaries AS (

    SELECT
        trip_id,
        COUNT(DISTINCT stop_id) AS n_stops,
        COUNT(*) AS n_stop_times,
        MIN(departure_time) AS trip_first_departure_ts,
        MAX(arrival_time) AS trip_last_arrival_ts
    FROM dim_stop_times
    GROUP BY trip_id

),

join_trips_stop_times AS (

    SELECT

        trip_id_summaries.trip_id,
        trip_id_summaries.n_stops,
        trip_id_summaries.n_stop_times,
        trip_id_summaries.trip_first_departure_ts,
        trip_id_summaries.trip_last_arrival_ts,

        dim_trips.key AS trip_key

    FROM trip_id_summaries
    LEFT JOIN dim_trips
        ON trip_id_summaries.trip_id = dim_trips.trip_id

)

SELECT * FROM join_trips_stop_times
