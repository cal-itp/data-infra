WITH
latest AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__contracts'),
        order_by = 'time DESC', partition_by = 'dt'
        ) }}
),

base_tts_organizations_ct_organizations_map AS (
    SELECT * FROM {{ ref('base_tts_organizations_ct_organizations_map') }}
),

mapped_holder_ids AS (
    SELECT
        id,
        map_holder.ct_key AS contract_holder,
        map_vendor.ct_key AS contract_vendor,
        dt
    FROM latest
    LEFT JOIN UNNEST(latest.contract_holder) AS unnested_contract_holder
    LEFT JOIN UNNEST(latest.contract_vendor) AS unnested_contract_vendor
    LEFT JOIN base_tts_organizations_ct_organizations_map AS map_holder
        ON unnested_contract_holder = map_holder.tts_key
        AND dt = map_holder.tts_date
    LEFT JOIN base_tts_organizations_ct_organizations_map AS map_vendor
        ON unnested_contract_vendor = map_vendor.tts_key
        AND dt = map_vendor.tts_date
),

stg_transit_database__contracts AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
        map.contract_holder AS contract_holder_organization_key,
        map.contract_vendor AS contract_vendor_organization_key,
        covered_components,
        value,
        start_date,
        end_date,
        renewal_option,
        notes,
        contract_name AS contract_name_notes,
        attachments,
        dt AS calitp_extracted_at
    FROM latest
    LEFT JOIN mapped_holder_ids AS map
        USING(id, dt)
)

SELECT * FROM stg_transit_database__contracts
