WITH customers_table AS (

    SELECT * FROM {{ ref('joined_micropayments_customers_adjustments_products') }}

),

routes_and_transactions AS (

    SELECT * FROM {{ ref('routes_and_transactions') }}

),

payments_rides AS (

    SELECT

        m.participant_id,
        m.micropayment_id,

        -- Customer and funding source information
        m.funding_source_vault_id,
        m.customer_id,
        m.principal_customer_id,
        m.bin,
        m.masked_pan,
        m.card_scheme,
        m.issuer,
        m.issuer_country,
        m.form_factor,

        m.charge_amount,
        m.refund_amount,
        m.nominal_amount,
        m.charge_type,
        m.adjustment_id,
        m.adjustment_type,
        m.adjustment_time_period_type,
        m.adjustment_description,
        m.adjustment_amount,
        m.product_id,
        m.product_code,
        m.product_description,
        m.product_type,

        -- Common transaction info
        r.route_id,
        r.route_long_name,
        r.route_short_name,
        r.direction,
        r.vehicle_id,

        -- Tap on or single transaction info
        r.littlepay_transaction_id,
        r.device_id,
        r.transaction_type,
        r.transaction_outcome,
        r.transaction_date_time_utc,
        r.transaction_date_time_pacific,
        r.location_id,
        r.location_name,
        r.latitude,
        r.longitude,

        -- Tap off transaction info
        r.off_littlepay_transaction_id,
        r.off_device_id,
        r.off_transaction_type,
        r.off_transaction_outcome,
        r.off_transaction_date_time_utc,
        r.off_transaction_date_time_pacific,
        r.off_location_id,
        r.off_location_name,
        r.off_latitude,
        r.off_longitude

    FROM customers_table AS m
    INNER JOIN routes_and_transactions AS r
        USING (participant_id, micropayment_id)
)

SELECT * FROM payments_rides
