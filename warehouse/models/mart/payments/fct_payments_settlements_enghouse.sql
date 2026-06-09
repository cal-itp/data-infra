{{ config(materialized = 'table',
    post_hook="{{ payments_enghouse_row_access_policy() }}") }}

WITH transactions AS (
    SELECT * FROM {{ ref('stg_enghouse__transactions') }}
),

payments_entity_mapping AS (
    SELECT
        * EXCEPT(enghouse_operator_id),
        enghouse_operator_id AS operator_id
    FROM {{ ref('payments_entity_mapping_enghouse') }}
),

dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

join_orgs AS (
    SELECT
        transactions.operator_id,
        transactions.id,
        transactions.operation,
        transactions.terminal_id,
        transactions.mapping_terminal_id,
        transactions.mapping_merchant_id,
        transactions.timestamp,
        transactions.amount,
        transactions.payment_reference,
        transactions.spdh_response,
        transactions.response_type,
        transactions.response_message,
        transactions.token,
        transactions.issuer_response,
        transactions.core_response,
        transactions.rrn,
        transactions.authorization_code,
        transactions.par,
        transactions.brand,
        transactions._content_hash,

        dim_orgs.name AS organization_name,
        direct_map.organization_source_record_id,
    FROM transactions
    LEFT JOIN payments_entity_mapping AS direct_map
        ON transactions.operator_id = direct_map.operator_id
            AND CAST(transactions.timestamp AS TIMESTAMP)
                BETWEEN CAST(direct_map._in_use_from AS TIMESTAMP)
                AND CAST(direct_map._in_use_until AS TIMESTAMP)
    LEFT JOIN dim_orgs
        ON direct_map.organization_source_record_id = dim_orgs.source_record_id
        AND CAST(transactions.timestamp AS TIMESTAMP) BETWEEN dim_orgs._valid_from AND dim_orgs._valid_to
),

fct_payments_settlements_enghouse AS (
    SELECT
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
        organization_name,
        organization_source_record_id,
        LAST_DAY(EXTRACT(DATE FROM timestamp AT TIME ZONE "America/Los_Angeles"), MONTH) AS end_of_month_date_pacific,
        LAST_DAY(EXTRACT(DATE FROM timestamp), MONTH) AS end_of_month_date_utc,
        _content_hash
    FROM join_orgs
)

SELECT * FROM fct_payments_settlements_enghouse
