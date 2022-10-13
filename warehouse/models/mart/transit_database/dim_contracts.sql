{{ config(materialized='table') }}

WITH

stg_transit_database__contracts AS (
    SELECT * FROM {{ ref('stg_transit_database__contracts') }}
),

contracts_scd AS (
    SELECT
        {{ dbt_utils.surrogate_key(['record_id', 'ts']) }} AS key,
        record_id,
        name,
        contract_holder_organization_record_id,
        contract_vendor_organization_record_id,
        value,
        start_date,
        end_date,
        renewal_option,
        notes,
        contract_name_notes,
        ts AS _valid_from,
        LEAD({{ make_end_of_valid_range('ts') }}, 1, CAST("2099-01-01" AS TIMESTAMP)) OVER (PARTITION BY record_id ORDER BY ts) AS _valid_to
    FROM stg_transit_database__contracts
),

dim_contracts AS (
    SELECT *, _valid_to = CAST("2099-01-01" AS TIMESTAMP) AS is_latest
    FROM contracts_scd
)

SELECT * FROM dim_contracts
