WITH

once_daily_contracts AS (
    SELECT *
    -- have to use base table to get the california transit base organization record ids
    FROM {{ ref('base_tts_contracts_idmap') }}
),

stg_transit_database__contracts AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
        unnested_contract_holder AS contract_holder_organization_key,
        unnested_contract_vendor AS contract_vendor_organization_key,
        covered_components,
        value,
        start_date,
        end_date,
        renewal_option,
        notes,
        contract_name AS contract_name_notes,
        attachments,
        dt AS calitp_extracted_at
    FROM once_daily_contracts
    LEFT JOIN UNNEST(once_daily_contracts.contract_holder) AS unnested_contract_holder
    LEFT JOIN UNNEST(once_daily_contracts.contract_vendor) AS unnested_contract_vendor
)

SELECT * FROM stg_transit_database__contracts
