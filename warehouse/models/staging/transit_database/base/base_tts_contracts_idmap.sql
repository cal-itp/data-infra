WITH
latest AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__contracts'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

base_tts_organizations_ct_organizations_map AS (
    SELECT * FROM {{ ref('base_tts_organizations_ct_organizations_map') }}
),

mapped_org_ids AS (
    SELECT
        id,
        ARRAY_AGG(map_holder.ct_key IGNORE NULLS) AS contract_holder,
        ARRAY_AGG(map_vendor.ct_key IGNORE NULLS) AS contract_vendor,
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
