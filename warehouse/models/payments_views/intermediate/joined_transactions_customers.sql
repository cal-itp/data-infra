WITH joined_initial_transactions_second_transactions AS (

    SELECT * FROM {{ ref('joined_initial_transactions_second_transactions') }}

),

joined_micropayments_customers_adjustments_products AS (

    SELECT * FROM {{ ref('joined_micropayments_customers_adjustments_products') }}

),

joined_transactions_customers AS (

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
        t1.route_id,

        t1.direction,
        t1.vehicle_id,

        -- Tap on or single transaction info
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

        -- Tap off transaction info
        t1.off_littlepay_transaction_id,
        t1.off_device_id,
        t1.off_transaction_type,
        t1.off_transaction_outcome,
        t1.off_transaction_date_time_utc,
        t1.off_transaction_date_time_pacific,
        t1.off_location_id,
        t1.off_location_name,
        t1.off_latitude,
        t1.off_longitude
    FROM joined_micropayments_customers_adjustments_products AS m
    INNER JOIN joined_initial_transactions_second_transactions AS t1 USING (participant_id, micropayment_id)

)

SELECT * FROM joined_transactions_customers
