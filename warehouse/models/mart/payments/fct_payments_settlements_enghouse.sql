{{ config(materialized = 'table',
    post_hook="{{ payments_enghouse_row_access_policy() }}") }}

WITH transactions AS (
    SELECT *
    FROM {{ ref('stg_enghouse__transactions') }}
),

payments_entity_mapping AS (
    SELECT
        * EXCEPT(enghouse_operator_id),
        enghouse_operator_id AS operator_id
    FROM {{ ref('payments_entity_mapping_enghouse') }}
),

orgs AS (
    SELECT * FROM {{ ref('dim_organizations') }}
),

join_orgs AS (
    SELECT
        transactions.*,
        orgs.name AS organization_name,
        orgs.source_record_id AS organization_source_record_id,
    FROM transactions
    LEFT JOIN payments_entity_mapping
        ON transactions.operator_id = payments_entity_mapping.operator_id
        AND CAST(transactions.timestamp AS TIMESTAMP)
            BETWEEN CAST(payments_entity_mapping._in_use_from AS TIMESTAMP)
            AND CAST(payments_entity_mapping._in_use_until AS TIMESTAMP)
    LEFT JOIN orgs
        ON payments_entity_mapping.organization_source_record_id = orgs.source_record_id
        AND CAST(transactions.timestamp AS TIMESTAMP) BETWEEN orgs._valid_from AND orgs._valid_to
),

fct_payments_settlements AS (
    SELECT
        organization_name,
        organization_source_record_id,
        operator_id,
        id,
        operation,
        terminal_id,
        mapping_terminal_id,
        mapping_merchant_id,
        timestamp,
        amount,
        payment_reference,
        spdh_response,
        response_type,
        response_message,
        token,
        issuer_response,
        core_response,
        rrn,
        authorization_code,
        par,
        brand,
        LAST_DAY(EXTRACT(DATE FROM timestamp AT TIME ZONE "America/Los_Angeles"), MONTH) AS end_of_month_date_pacific,
        LAST_DAY(EXTRACT(DATE FROM timestamp), MONTH) AS end_of_month_date_utc,
        _content_hash
    FROM join_orgs
)

SELECT * FROM fct_payments_settlements
