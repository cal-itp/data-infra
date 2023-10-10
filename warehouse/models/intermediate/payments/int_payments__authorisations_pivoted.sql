{{ config(materialized = 'table',) }}

WITH auth AS (
    SELECT *
    FROM {{ ref('int_payments__authorisations_deduped') }}
),

count_by_request_type AS (
    SELECT
        aggregation_id,
        request_type,
        COUNT(*) AS num_auth
    FROM auth
    GROUP BY 1, 2
),

look_up_current_status AS (
    SELECT DISTINCT
        aggregation_id,
        LAST_VALUE(request_type) OVER(PARTITION BY aggregation_id ORDER BY authorisation_date_time_utc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS current_request_type,
        LAST_VALUE(status) OVER(PARTITION BY aggregation_id ORDER BY authorisation_date_time_utc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS current_status,
    FROM auth
),

final_update_by_request_type AS (
    SELECT
        aggregation_id,
        authorisation_date_time_utc,
        status,
        retrieval_reference_number,
        request_type,
        transaction_amount,
        currency_code,
        num_auth
    FROM auth
    LEFT JOIN count_by_request_type USING (aggregation_id, request_type)
    -- get latest only by request type
    QUALIFY ROW_NUMBER() OVER(PARTITION BY aggregation_id, request_type ORDER BY authorisation_date_time_utc DESC) = 1
),

pivoted AS (
    SELECT
        *
    FROM
        (SELECT

            aggregation_id,
            currency_code,
            authorisation_date_time_utc,
            transaction_amount,
            status,
            retrieval_reference_number,
            num_auth,
            request_type

        FROM final_update_by_request_type)
    PIVOT(
        MAX(authorisation_date_time_utc) AS final_auth_datetime,
        MAX(status) AS final_status,
        MAX(retrieval_reference_number) AS final_rrn,
        MAX(num_auth) AS num_auth,
        MAX(transaction_amount) AS final_transaction_amount
        FOR request_type IN
        ('AUTHORISATION', 'DEBT_RECOVERY_AUTHCHECK', 'DEBT_RECOVERY_REVERSAL', 'CARD_CHECK')
    )

),

int_payments__authorisations_pivoted AS (
    SELECT
        *
    FROM pivoted
    LEFT JOIN look_up_current_status USING (aggregation_id)
)

SELECT * FROM int_payments__authorisations_pivoted
