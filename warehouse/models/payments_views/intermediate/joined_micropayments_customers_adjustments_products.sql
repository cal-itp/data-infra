WITH joined_micropayments_customers AS (

    SELECT * FROM {{ ref('joined_micropayments_customers') }}

),

applied_adjustments AS (

    SELECT * FROM {{ ref('applied_adjustments') }}

),

stg_cleaned_product_data AS (

    SELECT * FROM {{ ref('stg_cleaned_product_data') }}

),

joined_micropayments_customers_adjustments_products AS (

    SELECT
        m.participant_id,
        m.micropayment_id,
        m.transaction_time,

        -- Customer and funding source information
        m.funding_source_vault_id,
        m.customer_id,
        m.charge_amount,
        m.refund_amount,
        m.nominal_amount,
        m.charge_type,
        m.principal_customer_id,
        m.bin,
        m.masked_pan,
        m.card_scheme,
        m.issuer,
        m.issuer_country,
        m.form_factor,
        a.adjustment_id,
        a.type AS adjustment_type,
        a.time_period_type AS adjustment_time_period_type,
        a.description AS adjustment_description,
        a.amount AS adjustment_amount,
        p.product_id,
        p.product_code,
        p.product_description,
        p.product_type

    FROM joined_micropayments_customers AS m
    LEFT JOIN applied_adjustments AS a USING (participant_id, micropayment_id)
    LEFT JOIN stg_cleaned_product_data AS p USING (participant_id, product_id)
)

SELECT * FROM joined_micropayments_customers_adjustments_products
