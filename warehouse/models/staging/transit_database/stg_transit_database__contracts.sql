WITH

source AS (
    SELECT * FROM {{ source('airtable', 'transit_technology_stacks__contracts') }}
)

base_tts_organizations_ct_organizations_map AS (
    SELECT * FROM {{ ref('base_tts_organizations_ct_organizations_map') }}
),

mapped_org_ids AS (
    SELECT
        id,
        ARRAY_AGG(map_holder.ct_key IGNORE NULLS) AS contract_holder,
        ARRAY_AGG(map_vendor.ct_key IGNORE NULLS) AS contract_vendor,
        dt
    FROM source
    LEFT JOIN UNNEST(latest.contract_holder) AS unnested_contract_holder
    LEFT JOIN UNNEST(latest.contract_vendor) AS unnested_contract_vendor
    LEFT JOIN base_tts_organizations_ct_organizations_map AS map_holder
        ON unnested_contract_holder = map_holder.tts_key
        AND dt = map_holder.tts_date
    LEFT JOIN base_tts_organizations_ct_organizations_map AS map_vendor
        ON unnested_contract_vendor = map_vendor.tts_key
        AND dt = map_vendor.tts_date
    GROUP BY id, dt
),

base_tts_contracts_idmap AS (
    SELECT
        r.* EXCEPT(contract_holder, contract_vendor),
        map.contract_holder,
        map.contract_vendor
    FROM latest as r
    LEFT JOIN mapped_org_ids AS map
        USING(id, dt)
)

SELECT * FROM base_tts_contracts_idmap


stg_transit_database__contracts AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
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
