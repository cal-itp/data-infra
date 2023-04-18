WITH source AS (
    SELECT * FROM {{ littlepay_source('external_littlepay', 'micropayment_adjustments') }}
),

stg_littlepay__micropayment_adjustments AS (
    SELECT
        micropayment_id,
        adjustment_id,
        participant_id,
        customer_id,
        product_id,
        type,
        description,
        amount,
        time_period_type,
        {{ safe_cast('applied', type_boolean()) }} AS applied,
        zone_ids_us,
        _line_number,
        `instance`,
        extract_filename,
        ts,
    FROM source
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            micropayment_id,
            adjustment_id,
            participant_id,
            customer_id,
            product_id,
            type,
            description,
            amount,
            time_period_type,
            applied,
            zone_ids_us
        ORDER BY littlepay_export_ts DESC
    ) = 1
)

SELECT * FROM stg_littlepay__micropayment_adjustments
