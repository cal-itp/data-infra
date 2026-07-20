WITH
latest AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__payment_device_mapping'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

base_tts_organizations_ct_organizations_map AS (
    SELECT * FROM {{ ref('base_tts_organizations_ct_organizations_map') }}
),

mapped_org_ids AS (
    SELECT
        id,
        ARRAY_AGG(map_agency.ct_key IGNORE NULLS) AS agency,
        dt
    FROM latest
    LEFT JOIN UNNEST(latest.agency) AS unnested_agency
    LEFT JOIN base_tts_organizations_ct_organizations_map AS map_agency
        ON unnested_agency = map_agency.tts_key
        AND dt = map_agency.tts_date
    GROUP BY id, dt
),

base_tts_payment_device_mapping_idmap AS (
    SELECT
        r.* EXCEPT(agency),
        map.agency
    FROM latest as r
    LEFT JOIN mapped_org_ids AS map
        USING (id, dt)
)

SELECT * FROM base_tts_payment_device_mapping_idmap
