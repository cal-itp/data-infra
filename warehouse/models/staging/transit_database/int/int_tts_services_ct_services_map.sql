WITH

ct_services AS (
    SELECT *
    FROM {{ source('airtable', 'california_transit__services') }}
    WHERE TRIM(name) != ""
),

tts_services AS (
    SELECT *
    FROM {{ source('airtable', 'transit_technology_stacks__services') }}
    WHERE TRIM(name) != ""
),

int_tts_services_ct_services_map AS (
    {{ transit_database_synced_table_id_mapping(
        table_a_dict = {'table_name': 'ct_services',
            'base': 'ct',
            'id_col': 'service_id'
        },
        table_b_dict = {'table_name': 'tts_services',
            'base': 'tts',
            'id_col': 'service_id'
        }) }}
)

SELECT * FROM int_tts_services_ct_services_map
