{{ config(materialized='table') }}

WITH stg_transit_database__contracts AS (
    SELECT * FROM {{ ref('stg_transit_database__contracts') }}
),

dim_contracts AS (
    SELECT
        contract_id,
        contract_name,
        contract_type_functional_category,
        contract_type_functions,
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
