{{ config(materialized = "table") }}

WITH auth AS (
    SELECT *
    FROM {{ ref('int_littlepay__unioned_authorisations') }}
),

settlement_rrns AS (
    SELECT DISTINCT retrieval_reference_number
    FROM {{ ref('stg_littlepay__settlements') }}
),

-- as of 10/10/23, we have two aggregation_id/authorisation_date_time_utc pairs that are duplicates
-- for one of them, we want to keep the one that has an RRN that appears in settlements
-- for the other, neither RRN appears in settlements, so we can just keep the later line number
identify_dups AS (
    SELECT
        _payments_key,
        COUNT(DISTINCT _key) > 1 AS is_dup,
        COUNTIF(settlement_rrns.retrieval_reference_number IS NOT NULL) > 0 AS payment_key_has_settlement
    FROM auth
    LEFT JOIN settlement_rrns USING (retrieval_reference_number)
    GROUP BY 1
),

dedupe_criteria AS (
    SELECT
        auth.*,
        is_dup,
        payment_key_has_settlement,
        settlement_rrns.retrieval_reference_number IS NOT NULL AS has_settlement,
        ROW_NUMBER() OVER (PARTITION BY _payments_key ORDER BY littlepay_export_ts DESC, _line_number DESC) AS payments_key_appearance_num,
    FROM auth
    LEFT JOIN identify_dups USING (_payments_key)
    LEFT JOIN settlement_rrns USING (retrieval_reference_number)
),

int_payments__authorisations_deduped AS (
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
    FROM dedupe_criteria
    -- filter out duplicate row where RRN doesn't map to a settlement (but its duplicate's RRN does map)
    -- and filter out duplicate row where both have RRNs but neither maps to a settlement
    WHERE (NOT is_dup) OR (is_dup AND has_settlement) OR (is_dup AND NOT payment_key_has_settlement AND payments_key_appearance_num = 1)
)

SELECT * FROM int_payments__authorisations_deduped
