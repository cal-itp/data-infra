{{ config(materialized='table') }}

WITH stg_transit_database__contracts AS (
    SELECT * FROM {{ ref('stg_transit_database__contracts') }}
),

dim_contracts AS (
    SELECT
        key,
        name,
        contract_holder_organization_key,
        contract_vendor_organization_key,
        value,
        start_date,
        end_date,
        renewal_option,
        notes,
        contract_name_notes,
        calitp_extracted_at
    FROM stg_transit_database__contracts
)

SELECT * FROM dim_contracts
