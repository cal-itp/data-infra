{{ config(materialized = 'table',
    post_hook="{{ payments_littlepay_row_access_policy() }}") }}

WITH authorisations AS (
    SELECT *
    FROM {{ ref('int_payments__authorisations_deduped') }}
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

join_orgs AS (
    SELECT
        authorisations.*,
        orgs.name AS organization_name,
        orgs.source_record_id AS organization_source_record_id,
    FROM authorisations
    LEFT JOIN payments_entity_mapping
        ON authorisations.participant_id = payments_entity_mapping.participant_id
        AND CAST(authorisations.record_updated_timestamp_utc AS TIMESTAMP)
            BETWEEN CAST(payments_entity_mapping._in_use_from AS TIMESTAMP)
            AND CAST(payments_entity_mapping._in_use_until AS TIMESTAMP)
    LEFT JOIN orgs
        ON payments_entity_mapping.organization_source_record_id = orgs.source_record_id
        AND CAST(authorisations.record_updated_timestamp_utc AS TIMESTAMP) BETWEEN orgs._valid_from AND orgs._valid_to
),

fct_payments_authorisations AS (
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

SELECT * FROM fct_payments_authorisations



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
        _content_hash

SELECT * FROM int_payments__authorisations_deduped
