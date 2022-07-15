{{ config(materialized='table') }}

WITH latest_contracts AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__contracts'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
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
    FROM latest_contracts
)

SELECT * FROM dim_contracts
