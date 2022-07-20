WITH joined_initial_transactions_second_transactions AS (

    SELECT
        t1.micropayment_id,
        t1.route_id AS t1_route_id,
        t2.route_id AS t2_route_id,
        t1.participant_id,
        t1.direction,
        t1.vehicle_id,

        t1.littlepay_transaction_id,
        t1.device_id,
        t1.transaction_type,
        t1.transaction_outcome,
        t1.transaction_date_time_utc,
        t1.transaction_date_time_pacific,
        t1.location_id,
        t1.location_name,
        t1.latitude,
        t1.longitude,

        t2.littlepay_transaction_id AS off_littlepay_transaction_id,
        t2.device_id AS off_device_id,
        t2.transaction_type AS off_transaction_type,
        t2.transaction_outcome AS off_transaction_outcome,
        t2.transaction_date_time_utc AS off_transaction_date_time_utc,
        t2.transaction_date_time_pacific AS off_transaction_date_time_pacific,
        t2.location_id AS off_location_id,
        t2.location_name AS off_location_name,
        t2.latitude AS off_latitude,
        t2.longitude AS off_longitude,
        CASE WHEN t1.route_id != 'Route Z' THEN t1.route_id ELSE COALESCE(t2.route_id, 'Route Z') END AS route_id

    FROM {{ ref('initial_transactions') }} AS t1
    LEFT JOIN {{ ref('second_transactions') }} AS t2 USING (participant_id, micropayment_id)
)

SELECT * FROM joined_initial_transactions_second_transactions
