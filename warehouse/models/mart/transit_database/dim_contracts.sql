{{ config(materialized='table') }}

WITH int_transit_database__contracts_dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__contracts_dim') }}
),

dim_contracts AS (
    SELECT
        key,
        name,
        contract_holder_organization_key,
        contract_vendor_organization_key,
        value,
        start_date,
        source_record_id,
        end_date,
        is_active,
        renewal_option,
        notes,
        contract_name_notes,
        _is_current,
        _valid_from,
        _valid_to
    FROM int_transit_database__contracts_dim
)

SELECT * FROM dim_contracts
