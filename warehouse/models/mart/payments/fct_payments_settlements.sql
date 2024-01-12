{{ config(materialized = 'table',
    post_hook="{{ payments_littlepay_row_access_policy() }}") }}

WITH settlements AS (
    SELECT *
    FROM {{ ref('stg_littlepay__settlements') }}
),

payments_entity_mapping AS (
    SELECT
        * EXCEPT(littlepay_participant_id),
        littlepay_participant_id AS participant_id
    FROM {{ ref('payments_entity_mapping') }}
),

orgs AS (
    SELECT * FROM {{ ref('dim_organizations') }}
),

-- some rows have null settlement type (debit vs. credit)
-- so we try to impute based on settlement order
impute_settlement_type AS (
    SELECT
        * EXCEPT(settlement_type),
        COALESCE(settlement_type,
            -- when a settlement (aggregation_id / RRN) appears multiple times, it is generally because the subsequent lines are refunds
            -- vast majority of refunds have exactly one debit line and one credit (refund) line, but there are a few oddities with multiple credit (refund) lines
            CASE
                WHEN ROW_NUMBER() OVER(PARTITION BY aggregation_id, retrieval_reference_number ORDER BY record_updated_timestamp_utc) > 1 THEN "CREDIT"
                ELSE "DEBIT"
            END
        ) AS settlement_type,
        settlement_type IS NULL AS imputed_type,
    FROM settlements
),

join_orgs AS (
    SELECT
        impute_settlement_type.*,
        orgs.name AS organization_name,
        orgs.source_record_id AS organization_source_record_id,
    FROM impute_settlement_type
    LEFT JOIN payments_entity_mapping USING (participant_id)
    LEFT JOIN orgs
        ON payments_entity_mapping.organization_source_record_id = orgs.source_record_id
        AND CAST(impute_settlement_type.record_updated_timestamp_utc AS TIMESTAMP) BETWEEN orgs._valid_from AND orgs._valid_to
),

fct_payments_settlements AS (
    SELECT
        organization_name,
        organization_source_record_id,
        settlement_id,
        participant_id,
        aggregation_id,
        customer_id,
        funding_source_id,
        retrieval_reference_number,
        littlepay_reference_number,
        external_reference_number,
        settlement_type,
        record_updated_timestamp_utc,
        refund_id,
        acquirer_response_rrn,
        settlement_status,
        request_created_timestamp_utc,
        response_created_timestamp_utc,
        CASE
            WHEN settlement_type = "CREDIT" THEN -1*(transaction_amount)
            WHEN settlement_type = "DEBIT" THEN transaction_amount
        END AS transaction_amount,
        LAST_DAY(EXTRACT(DATE FROM record_updated_timestamp_utc AT TIME ZONE "America/Los_Angeles"), MONTH) AS end_of_month_date_pacific,
        LAST_DAY(EXTRACT(DATE FROM record_updated_timestamp_utc), MONTH) AS end_of_month_date_utc,
        imputed_type,
        acquirer,
        _line_number,
        `instance`,
        extract_filename,
        ts,
        _content_hash,
        littlepay_export_ts,
        littlepay_export_date,
        _key,
        _payments_key
    FROM join_orgs
)

SELECT * FROM fct_payments_settlements
