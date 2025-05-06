WITH
latest_ct AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__services'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

latest_tts AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__services'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

ct_services AS ( -- noqa: L045
    SELECT *
    FROM latest_ct
    WHERE TRIM(name) != ""
),

tts_services AS ( -- noqa: L045
    SELECT *
    FROM latest_tts
    WHERE TRIM(name) != ""
),

base_tts_services_ct_services_map AS (
    {{ transit_database_synced_table_id_mapping(
        table_a_dict = {'table_name': 'ct_services',
            'base': 'ct',
            'id_col': 'id'
        },
        table_b_dict = {'table_name': 'tts_services',
            'base': 'tts',
            'id_col': 'id'
        }) }}
)

SELECT * FROM base_tts_services_ct_services_map
