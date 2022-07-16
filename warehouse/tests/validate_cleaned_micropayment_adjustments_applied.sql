{{ config(store_failures = true) }}

-- Ensure that there is only one micropayment_adjustments record with applied
-- set to True for each micropayment.

-- tests:
-- check_empty:
--   - "*"

WITH validate_cleaned_micropayment_adjustments_applied AS (

    SELECT
        micropayment_id,
        count(*) AS num_applied_adjustments
    FROM {{ ref('stg_cleaned_micropayment_adjustments') }}
    WHERE applied IS True
    GROUP BY micropayment_id
    HAVING count(*) > 1
    ORDER BY count(*) DESC
)

SELECT * FROM validate_cleaned_micropayment_adjustments_applied
