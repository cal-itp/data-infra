WITH

source AS (
    SELECT * FROM {{ source('airtable', 'transit_technology_stacks__contracts') }}
),

base_tts_organizations_ct_organizations_map AS (
    SELECT * FROM {{ ref('base_tts_organizations_ct_organizations_map') }}
),

unnested_contracts AS (
    -- These are foreign keys in Airtable, which come through as 1-length arrays
    SELECT
        source.* EXCEPT(contract_holder, contract_vendor),
        unnested_contract_holder AS contract_holder,
        unnested_contract_vendor AS contract_vendor,
    FROM source
    LEFT JOIN UNNEST(source.contract_holder) AS unnested_contract_holder
    LEFT JOIN UNNEST(source.contract_vendor) AS unnested_contract_vendor
),

stg_transit_database__contracts AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        map_holder.ct_key AS contract_holder_organization_key,
        map_vendor.ct_key AS contract_vendor_organization_key,
        covered_components,
        value,
        start_date,
        end_date,
        renewal_option,
        notes,
        contract_name AS contract_name_notes,
        attachments,
        ts
    FROM unnested_contracts
    -- NOTE: this is actually a bit imprecise since this is also a type 2 table eventually
    LEFT JOIN base_tts_organizations_ct_organizations_map AS map_holder
        ON contract_holder = map_holder.tts_key
        AND ts between map_holder._valid_from and map_holder._valid_to
    LEFT JOIN base_tts_organizations_ct_organizations_map AS map_vendor
        ON contract_vendor = map_vendor.tts_key
        AND ts between map_vendor._valid_from and map_vendor._valid_to
)

SELECT * FROM stg_transit_database__contracts
