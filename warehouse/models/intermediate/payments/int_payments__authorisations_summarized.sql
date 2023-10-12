{{ config(materialized = 'table',) }}

WITH auth AS (
    SELECT *
    FROM {{ ref('int_payments__authorisations_deduped') }}
),

-- get the payments key values of rows that
final_update AS (
    SELECT
        _payments_key
    FROM auth
    QUALIFY ROW_NUMBER() OVER(PARTITION BY aggregation_id ORDER BY authorisation_date_time_utc DESC) = 1
),

int_payments__authorisations_summarized AS (
    SELECT
        participant_id,
        aggregation_id,
        acquirer_id,
        request_type,
        transaction_amount,
        currency_code,
        retrieval_reference_number,
        littlepay_reference_number,
        external_reference_number,
        response_code,
        status,
        authorisation_date_time_utc,
         _line_number,
        `instance`,
        extract_filename,
        littlepay_export_ts,
        littlepay_export_date,
        ts,
        _key,
        _payments_key,
        _content_hash,
    FROM final_update
    LEFT JOIN auth USING(_payments_key)
)

SELECT * FROM int_payments__authorisations_summarized
