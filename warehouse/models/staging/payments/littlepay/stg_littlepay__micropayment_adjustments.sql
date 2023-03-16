WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'micropayment_adjustments') }}
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
)

SELECT * FROM stg_littlepay__micropayment_adjustments
