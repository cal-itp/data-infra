WITH applied_adjustments AS (
    SELECT
        participant_id,
        micropayment_id,
        product_id,
        adjustment_id,
        type,
        time_period_type,
        description,
        amount
    FROM {{ ref('stg_cleaned_micropayment_adjustments') }}
    WHERE applied IS True
)

SELECT * FROM applied_adjustments
