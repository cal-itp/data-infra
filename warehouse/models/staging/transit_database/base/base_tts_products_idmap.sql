WITH
latest AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__products'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

base_tts_organizations_ct_organizations_map AS (
    SELECT * FROM {{ ref('base_tts_organizations_ct_organizations_map') }}
),

mapped_org_ids AS (
    SELECT
        id,
        ARRAY_AGG(map_vendor.ct_key IGNORE NULLS) AS vendor,
        dt
    FROM latest
    LEFT JOIN UNNEST(latest.vendor) AS unnested_vendor
    LEFT JOIN base_tts_organizations_ct_organizations_map AS map_vendor
        ON unnested_vendor = map_vendor.tts_key
        AND dt = map_vendor.tts_date
    GROUP BY id, dt
),

base_tts_products_idmap AS (
    SELECT
        r.* EXCEPT(vendor),
        map.vendor
    FROM latest as r
    LEFT JOIN mapped_org_ids AS map
        USING (id, dt)
)

SELECT * FROM base_tts_products_idmap
