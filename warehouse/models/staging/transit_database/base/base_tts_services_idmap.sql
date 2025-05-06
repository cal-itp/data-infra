WITH
latest AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__services'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

base_tts_services_ct_services_map AS (
    SELECT * FROM {{ ref('base_tts_services_ct_services_map') }}
),


base_tts_services_idmap AS (
    SELECT
        T2.ct_key AS id,
        T1.* EXCEPT(id)
    FROM latest AS T1
    INNER JOIN base_tts_services_ct_services_map AS T2
        ON T1.id = T2.tts_key
        AND T1.dt = T2.tts_date
)

SELECT * FROM base_tts_services_idmap
