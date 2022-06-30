WITH stg_rt__vehicle_positions AS (
    SELECT * FROM {{ ref('stg_rt__vehicle_positions') }}
),

test_rt_trips AS (
    SELECT DISTINCT
     calitp_itp_id,
     calitp_url_number,
     date,
     trip_id,
     vehicle_id

    FROM stg_rt__vehicle_positions

    WHERE calitp_itp_id = 300
        AND date in ('2022-05-25', '2022-05-26')
)

SELECT * FROM test_rt_trips