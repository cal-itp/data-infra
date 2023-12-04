{{
    config(
        materialized='table',
    )
}}

WITH int_payments__cleaned_micropayment_device_transactions AS (
    SELECT * FROM {{ ref('int_payments__cleaned_micropayment_device_transactions') }}
),

stg_littlepay__device_transactions AS (
    SELECT * FROM {{ ref('stg_littlepay__device_transactions') }}
),

-- we only want transactions associated with valid micropayments
valid_transactions AS (
  SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY micropayment_id ORDER BY transaction_date_time_utc) AS row_num
  FROM int_payments__cleaned_micropayment_device_transactions
  INNER JOIN stg_littlepay__device_transactions USING (littlepay_transaction_id)
),

match_ids AS (
  SELECT
    tap_on.participant_id,
    tap_on.micropayment_id,
    tap_on.littlepay_transaction_id,
    tap_off.littlepay_transaction_id AS off_littlepay_transaction_id
  FROM valid_transactions AS tap_on
  LEFT JOIN valid_transactions AS tap_off
    ON tap_on.micropayment_id = tap_off.micropayment_id
    AND tap_on.participant_id = tap_off.participant_id
    -- in experiments, it seems like just naively using timestamp is better than using tap_on.type = "on" and tap_off.type = "off"
    -- because it seems like not all tap type designations are correct
    AND tap_off.transaction_date_time_utc > tap_on.transaction_date_time_utc
  -- the grain of this table should be one row per micropayment with up to two taps
  WHERE tap_on.row_num = 1
),

int_payments__matched_device_transactions AS (
    SELECT
        first_tap.participant_id,
        pairs.micropayment_id,
        COALESCE(first_tap.route_id, second_tap.route_id) AS route_id,
        first_tap.direction,
        first_tap.vehicle_id,
        first_tap.littlepay_transaction_id,
        first_tap.device_id,
        first_tap.type AS transaction_type,
        first_tap.transaction_outcome,
        first_tap.transaction_date_time_utc,
        first_tap.transaction_date_time_pacific,
        first_tap.location_id,
        first_tap.location_name,
        -- TODO: these lat/long values are repeated (with and without on_ prefix)
        first_tap.latitude,
        first_tap.longitude,
        first_tap.latitude AS on_latitude,
        first_tap.longitude AS on_longitude,
        first_tap.geography AS on_geography,
        second_tap.device_id AS off_device_id,
        second_tap.type AS off_transaction_type,
        second_tap.transaction_outcome AS off_transaction_outcome,
        second_tap.transaction_date_time_utc AS off_transaction_date_time_utc,
        second_tap.transaction_date_time_pacific AS off_transaction_date_time_pacific,
        second_tap.location_id AS off_location_id,
        second_tap.location_name AS off_location_name,
        second_tap.latitude AS off_latitude,
        second_tap.longitude AS off_longitude,
        second_tap.geography AS off_geography,
        DATETIME_DIFF(
            second_tap.transaction_date_time_pacific,
            first_tap.transaction_date_time_pacific,
            MINUTE
        ) AS duration,
        ST_DISTANCE(first_tap.geography, second_tap.geography) AS distance_meters,
        SAFE_CAST(first_tap.transaction_date_time_pacific AS DATE) AS transaction_date_pacific,
        EXTRACT(DAYOFWEEK FROM first_tap.transaction_date_time_pacific) AS day_of_week
    FROM match_ids AS pairs
    LEFT JOIN stg_littlepay__device_transactions AS first_tap
        ON pairs.littlepay_transaction_id = first_tap.littlepay_transaction_id
    LEFT JOIN stg_littlepay__device_transactions AS second_tap
        ON pairs.off_littlepay_transaction_id = second_tap.littlepay_transaction_id
)

SELECT * FROM int_payments__matched_device_transactions
