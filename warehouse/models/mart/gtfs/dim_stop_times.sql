{{
    config(
        cluster_by=['_valid_from', 'warning_duplicate_primary_key'],
    )
}}

WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__stop_times'),
    ) }}
),

raw_time_parts AS (
    SELECT
        *,
        REGEXP_EXTRACT_ALL(arrival_time, "([0-9]+)") AS part_arr,
        REGEXP_EXTRACT_ALL(departure_time, "([0-9]+)") AS part_dep
    FROM make_dim
),

int_time_parts AS (
    SELECT
        * EXCEPT (part_arr, part_dep),
        ARRAY(
            SELECT CAST(num AS INT64)
            FROM UNNEST(raw_time_parts.part_arr) AS num
        ) AS part_arr,
        ARRAY(
            SELECT CAST(num AS INT64)
            FROM UNNEST(raw_time_parts.part_dep) AS num
        ) AS part_dep
    FROM raw_time_parts
),

array_len_fix AS (
    SELECT
        * EXCEPT(part_arr, part_dep),
        CASE
            WHEN
                ARRAY_LENGTH(part_arr) = 0 THEN [NULL, NULL, NULL]
            ELSE part_arr
        END AS part_arr,
        CASE
            WHEN
                ARRAY_LENGTH(part_dep) = 0 THEN [NULL, NULL, NULL]
            ELSE part_dep
        END AS part_dep
    FROM int_time_parts
),

dim_stop_times AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'trip_id', 'stop_sequence']) }} AS key,
        base64_url,
        feed_key,
        trip_id,
        stop_id,
        stop_sequence,
        arrival_time,
        departure_time,
        stop_headsign,
        pickup_type,
        drop_off_type,
        continuous_pickup,
        continuous_drop_off,
        shape_dist_traveled,
        timepoint,
        COUNT(
            *
        ) OVER (
            PARTITION BY base64_url, ts, trip_id, stop_sequence
        ) > 1 AS warning_duplicate_primary_key,
        stop_id IS NULL AS warning_missing_foreign_key_stop_id,
        _valid_from,
        _valid_to,
        _is_current,
        part_arr[
            OFFSET(0)
        ] * 3600 + part_arr[
            OFFSET(1)
        ] * 60 + part_arr[OFFSET(2)] AS arrival_sec,
        part_dep[
            OFFSET(0)
        ] * 3600 + part_dep[
            OFFSET(1)
        ] * 60 + part_dep[OFFSET(2)] AS departure_sec
    FROM array_len_fix
)

SELECT * FROM dim_stop_times
