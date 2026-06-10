{{ config(materialized = 'table',
    post_hook="{{ payments_enghouse_row_access_policy() }}") }}

WITH deduped_transactions AS (
    SELECT
        operator_id,
        id,
        operation,
        terminal_id,
        timestamp,
        amount,
        payment_reference,
        response_type,
        response_message,
        token,
        issuer_response,
        rrn,
        authorization_code,
        par,
        brand,
        _content_hash,
    FROM {{ ref('stg_enghouse__deduped_transactions') }}
),

payments_entity_mapping AS (
    SELECT
        organization_source_record_id,
        enghouse_operator_id AS operator_id,
        _in_use_from,
        _in_use_until
    FROM {{ ref('payments_entity_mapping_enghouse') }}
),

dim_orgs AS (
    SELECT
        source_record_id,
        name,
        _valid_from,
        _valid_to
    FROM {{ ref('dim_organizations') }}
),

join_orgs AS (
    SELECT
        deduped_transactions.operator_id,
        deduped_transactions.id,
        deduped_transactions.operation,
        deduped_transactions.terminal_id,
        deduped_transactions.timestamp,
        deduped_transactions.amount,
        deduped_transactions.payment_reference,
        deduped_transactions.response_type,
        deduped_transactions.response_message,
        deduped_transactions.token,
        deduped_transactions.issuer_response,
        deduped_transactions.rrn,
        deduped_transactions.authorization_code,
        deduped_transactions.par,
        deduped_transactions.brand,
        deduped_transactions._content_hash,
        dim_orgs.name AS organization_name,
        direct_map.organization_source_record_id,
    FROM deduped_transactions
    LEFT JOIN payments_entity_mapping AS direct_map
        ON deduped_transactions.operator_id = direct_map.operator_id
            AND CAST(deduped_transactions.timestamp AS TIMESTAMP)
                BETWEEN CAST(direct_map._in_use_from AS TIMESTAMP)
                AND CAST(direct_map._in_use_until AS TIMESTAMP)
    LEFT JOIN dim_orgs
        ON direct_map.organization_source_record_id = dim_orgs.source_record_id
        AND CAST(deduped_transactions.timestamp AS TIMESTAMP) BETWEEN dim_orgs._valid_from AND dim_orgs._valid_to
),

fct_payments_settlements_enghouse AS (
    SELECT
        operator_id,
        id,
        operation,
        terminal_id,
        timestamp,
        amount,
        payment_reference,
        response_type,
        response_message,
        token,
        issuer_response,
        rrn,
        authorization_code,
        par,
        brand,
        CASE
            WHEN operation = 'REFUND' THEN 'CREDIT'
            ELSE 'DEBIT'
        END AS settlement_type,
        organization_name,
        organization_source_record_id,
        LAST_DAY(EXTRACT(DATE FROM timestamp AT TIME ZONE "America/Los_Angeles"), MONTH) AS end_of_month_date_pacific,
        LAST_DAY(EXTRACT(DATE FROM timestamp), MONTH) AS end_of_month_date_utc,
        _content_hash
    FROM join_orgs
)

SELECT
    operator_id,
    id,
    operation,
    terminal_id,
    timestamp,
    amount,
    payment_reference,
    response_type,
    response_message,
    token,
    issuer_response,
    rrn,
    authorization_code,
    par,
    brand,
    settlement_type,
    organization_name,
    organization_source_record_id,
    end_of_month_date_pacific,
    end_of_month_date_utc,
    _content_hash
FROM fct_payments_settlements_enghouse
