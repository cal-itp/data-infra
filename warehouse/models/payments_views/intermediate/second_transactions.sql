WITH second_transactions AS (

    SELECT

        t1.micropayment_id,
        t1.calitp_extracted_at,
        t1.calitp_hash,
        t1.calitp_export_account,
        t1.calitp_export_datetime,

        t2.device_transaction_id,
        t2.device_id_issuer,
        t2.type,
        t2.transction_deny_reason,
        t2.location_scheme,
        t2.zone_id,
        t2.mode,
        t2.granted_zone_ids,
        t2.onward_zone_ids,
        t2.route_id,
        t2.direction,
        t2.vehicle_id,
        t2.participant_id,
        t2.customer_id,
        -- Tap on or single transaction info
        t2.littlepay_transaction_id,
        t2.device_id,
        t2.transaction_outcome,
        t2.transaction_date_time_utc,
        t2.transaction_date_time_pacific,
        t2.location_id,
        t2.location_name,
        t2.latitude,
        t2.longitude,

        t3.transaction_type,
        t3.pending

    FROM {{ ref('stg_cleaned_micropayment_device_transactions') }} AS t1
    INNER JOIN {{ ref('stg_cleaned_device_transactions') }} AS t2 USING (littlepay_transaction_id)
    INNER JOIN {{ ref('stg_cleaned_device_transaction_types') }} AS t3 USING (littlepay_transaction_id)
    WHERE transaction_type = 'off'
)

SELECT * FROM second_transactions
