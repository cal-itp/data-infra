{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table_name = source('airtable', 'transit_technology_stacks__contracts'),
        columns = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__contracts AS (
    SELECT
        contract_id AS key,
        name,
        contract_type_functional_category,
        contract_type_functions,
        unnested_contract_holder AS contract_holder,
        unnested_contract_vendor AS contract_vendor,
        value,
        start_date,
        end_date,
        renewal_option,
        notes,
        contract_name AS contract_name_notes,
        attachments,
        dt AS calitp_extracted_at
    FROM latest,
        latest.contract_holder AS unnested_contract_holder,
        latest.contract_vendor AS unnested_contract_vendor
)

SELECT * FROM stg_transit_database__contracts
