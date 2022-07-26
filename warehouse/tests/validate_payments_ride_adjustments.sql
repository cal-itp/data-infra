{{ config(store_failures = true) }}

-- dst_table_name: "payments.invalid_payments_ride_adjustments"
-- Make sure that all rides where the amount paid is not equal to the nominal
-- amount have adjustments, and rides where the amount paid is equal to the
-- nominal amount do not have adjustments.

--tests:
--  check_empty:
--    - "*"

WITH validate_payments_ride_adjustments AS (

    SELECT

        charge_amount,
        nominal_amount,
        adjustment_id

    FROM views.payments_rides
    WHERE charge_amount != nominal_amount
        AND adjustment_id IS NULL

    UNION ALL

    SELECT

        charge_amount,
        nominal_amount,
        adjustment_id

    FROM views.payments_rides
    WHERE charge_amount = nominal_amount
        AND adjustment_id IS NOT NULL

)

SELECT * FROM validate_payments_ride_adjustments
