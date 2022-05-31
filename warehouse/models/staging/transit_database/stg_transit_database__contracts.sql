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
        contract_id,
        name AS contract_name,
        contract_type_functional_category,
        contract_type_functions,
        contract_holder,
        contract_vendor,
        value,
        start_date,
        end_date,
        renewal_option,
        notes,
        contract_name AS contract_name_notes,
        attachments.url AS attachment_url,
        dt AS calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__contracts
